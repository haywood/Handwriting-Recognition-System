#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <iostream>
#include <fstream>
#include <cassert>
#include <list>
#include <map>
#include <set>

#include "HWRecognition.h"

#define TRANS_MAX 100

using namespace std;
using namespace cv;

size_t getOptimalDCTSize(size_t N) { return 2*getOptimalDFTSize((N+1)/2); }

int main(int argc, char **argv)
{
    if (argc != 8) {
        cerr << "usage: " << argv[0] << " <dataDir> <transformScale> <featureHeight> <featureWidth> <perWriter> <testCount> <epsilonMin>\n";
        return 0;
    }

    string dataDir(argv[1]), wordsDir=dataDir+"/words/"; 
    string indexFilename=dataDir+"/wordswithwriters.txt"; 
    string imFilename, text;

    int transformScale=strtol(argv[2], NULL, 10);
    int featureHeight=strtol(argv[3], NULL, 10); 
    int featureWidth=strtol(argv[4], NULL, 10);
    int perWriter=strtol(argv[5], NULL, 10);
    int testCount=strtol(argv[6], NULL, 10);
    float epsilonMin=strtof(argv[7], NULL);

    int transformRows, transformCols;
    int lineNum, wordNum;
    int wordCount=0;

    if (transformScale <= 0 || transformScale > TRANS_MAX) {
        cerr << "error: illegal value for transformScale: " << transformScale
            << ". Should be 0 <= transformScale < " << TRANS_MAX << "\n";
        return 1;
    }

    if (perWriter < 2) {
        cerr << "error: illagal value for perWriter: " << perWriter
            << ". Must use at least two writing samples per person.\n";
        return 1;
    }

    if (testCount < 1 || testCount >= perWriter) {
        cerr << "error: illegal value for testCount: " << testCount
            << ". Must us at least one and no more than perWriter\n";
        return 1;
    }

    if (isnan(epsilonMin) || epsilonMin < 0 || epsilonMin > 1) {
        cerr << "error: illegal value for epsilonMin: " << epsilonMin 
            << ". Should be 0 <= epsilonMin <= 1.\n";
        return 1;
    }

    Mat img, padded, transform, features;
    ifstream indexFile(indexFilename.c_str());

    Size transformSize(transformScale, transformScale);
    WriterId writer;
    FormId form;

    map <WriterId, list<FormId> > writerToForm;

    map <FormId, Mat_<float> > formFeatures;
    map <FormId, list <Word> > forms;
    set <FormId> trainData;
    set <FormId>  testData;

    if (!indexFile.good()) {
        cerr << " error opening file: " << indexFilename << "\n";
        return 1;
    }

    while ((indexFile >> writer)) {

        indexFile >> form;
        indexFile >> lineNum;
        indexFile >> wordNum;
        indexFile >> imFilename;
        indexFile >> text;

        if (forms.count(form) || writerToForm[writer].size() < perWriter) {

            imFilename=wordsDir+imFilename;
            img=255-imread(imFilename, CV_LOAD_IMAGE_GRAYSCALE);
            if (img.empty()) {

                cerr << "unable to read image from file: " << imFilename << "\n";

            } else {

                // pad image for DCT
                transformRows=getOptimalDCTSize(img.rows);
                transformCols=getOptimalDCTSize(img.cols);

                copyMakeBorder(img, padded, 0, transformRows - img.rows, 0, transformCols - img.cols, BORDER_CONSTANT, Scalar::all(0));

                // scale intensities to the non-negative unit interval
                Mat_<float> wordImg((1.0f/255)*padded);

                dct(wordImg, transform); // perform DCT

                // rescale transform size to be uniform and then truncate to throw out high frequencies
                resize(transform, features, transformSize, 0, 0, INTER_LANCZOS4);
                features=features.rowRange(0, featureHeight).colRange(0, featureWidth);

                // create Word struct and save it
                Word record(imFilename, text, features.clone(), writer, form, lineNum, wordNum);
                wordCount++;

                // record new writer
                if (!writerToForm.count(writer)) writerToForm[writer];

                // record and count new form
                if (!forms.count(form)) {

                    // split into train and test data
                    if (writerToForm[writer].size() < testCount)
                        testData.insert(form);

                    else trainData.insert(form);

                    writerToForm[writer].push_back(form);
                    formFeatures[form]=features.clone();

                } else {
                    formFeatures[form]+=features;
                }

                forms[form].push_back(record);

            }
        }
    }

    // complete averaging of form representatives
    map<FormId, Mat_<float> >::iterator formIt=formFeatures.begin();
    while ( formIt != formFeatures.end() ) {
        formFeatures[formIt->first]/=forms[formIt->first].size();
        formIt++;
    }

    cout << "Read in " << wordCount << " words\n";

    set <FormId>::iterator trainForm;
    set <FormId>::iterator testForm;
    list <Word>::iterator testWord, trainWord;
    list <Word> testWordList, trainWordList;
    map <WriterId, int> votes;
    Mat_ <float> wordSim;
    float maxSim;
    WriterId guess, bestGuess;
    int correctForm=0;
    int correctWord=0; 
    int totalWord=0;
    int maxVotes;

    // loop through the forms in the test data
    testForm=testData.begin();
    while ( testForm != testData.end() ) {

        testWordList=forms[*testForm];
        writer=testWordList.front().writer;

        votes.clear();
        maxVotes=0;

        /*
        trainForm=trainData.begin();
        while ( trainForm != trainData.end() ) {
            matchTemplate(formFeatures[*testForm], formFeatures[*trainForm], wordSim, CV_TM_CCORR_NORMED);
            if (wordSim.at<float>(0,0) > maxSim) {
                maxSim=wordSim.at<float>(0,0);
                bestGuess=forms[*trainForm].front().writer;
            }
            trainForm++;
        }
        */

        // loop through words in the form
        testWord=testWordList.begin();
        while ( testWord != testWordList.end() ) {

            maxSim=0.0f;

            // loop through writers in the train data
            trainForm=trainData.begin();
            while ( trainForm != trainData.end() ) {
                
                trainWordList=forms[*trainForm];
                
                // loop through words in the writer
                trainWord=trainWordList.begin();
                while ( trainWord != trainWordList.end() ) {
                    matchTemplate(testWord->features, trainWord->features, wordSim, CV_TM_CCORR_NORMED);
                    if (wordSim.at<float>(0,0) > maxSim) {
                        maxSim=wordSim.at<float>(0,0);
                        guess=trainWord->writer;
                    }
                    trainWord++;
                }
                trainForm++;
            }

            if (maxSim > epsilonMin) {
                totalWord++;
                if (guess == testWord->writer)
                    correctWord++;

                cout << "Word " << totalWord << ", " 
                    << 100*((float)correctWord/totalWord) 
                    << "% accuracy on word writer, "
                    << testWord->writer << " => " << guess << ", " 
                    << "with similarity " << maxSim << "\n";

                votes[guess]++;
                if (votes[guess] > maxVotes) {
                    maxVotes=votes[guess];
                    bestGuess=guess;
                }
            }

            testWord++;

        }

        if (bestGuess == writer) correctForm++;

        testForm++;
    }

    cout << 100*((float)correctForm/testData.size()) << "% accuracy on form writer.\n";

    return 0;
}
