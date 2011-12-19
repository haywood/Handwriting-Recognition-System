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
    Mat_ <float> scaledImg;
    Mat_ <double> trainCovar(featureHeight*featureWidth, featureHeight*featureWidth);
    Mat_ <double> iTrainCovar(trainCovar.size());
    Mat_ <float> trainMean(featureHeight*featureWidth, 1);
    ifstream indexFile(indexFilename.c_str());

    WriterId writer;
    FormId form;

    map <WriterId, list<FormId> > writerToForm;

    vector <Mat_<float> > trainFeatures;
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
            img=imread(imFilename, CV_LOAD_IMAGE_GRAYSCALE);
            if (img.empty()) {

                cerr << "unable to read image from file: " << imFilename << "\n";

            } else {

                // invert the image intensities
                img=255-img;

                // pad image for DCT
                transformRows=getOptimalDCTSize(max(img.rows, transformScale));
                transformCols=getOptimalDCTSize(max(img.cols, transformScale));
                copyMakeBorder(img, padded, 0, transformRows - img.rows, 0, transformCols - img.cols, BORDER_CONSTANT, Scalar::all(0));

                // scale intensities to the non-negative unit interval
                normalize(padded, scaledImg, 0, 1.0, NORM_MINMAX, scaledImg.type());

                dct(scaledImg, transform); // perform DCT

                // rescale transform size to be uniform and then truncate to throw out high frequencies
                features=transform.rowRange(0, featureHeight).colRange(0, featureWidth);

                // scale into the interval [-1, 1]
                normalize(features, features, -1.0, 1.0, NORM_MINMAX);

                // create Word struct and save it
                Word record(imFilename, text, features.clone().reshape(0, featureHeight*featureWidth), writer, form, lineNum, wordNum);
                wordCount++;

                // record new writer
                if (!writerToForm.count(writer)) writerToForm[writer];

                // record and count new form
                if (!forms.count(form)) {

                    // split into train and test data
                    if (writerToForm[writer].size() < testCount)
                        testData.insert(form);

                    else {
                        trainFeatures.push_back(record.features);
                        trainData.insert(form);
                    }

                    writerToForm[writer].push_back(form);

                }

                forms[form].push_back(record);

            }
        }
    }

    img.release();
    padded.release();
    scaledImg.release();
    transform.release();
    features.release();

    calcCovarMatrix(&trainFeatures[0], trainFeatures.size(), trainCovar, trainMean, CV_COVAR_NORMAL);
    invert(trainCovar, iTrainCovar, DECOMP_SVD);

    cout << "Read in " << wordCount << " words\n";

    set <FormId>::iterator trainForm;
    set <FormId>::iterator testForm;
    list <Word>::iterator testWord, trainWord;
    map <WriterId, int>::iterator voteIt;

    list <Word> testWordList, trainWordList;
    map <WriterId, int> votes;
    float maxSim, wordSim;
    WriterId guess, bestGuess;
    int correctForm=0;
    int correctWord=0; 
    int totalForm=0;
    int totalWord=0;
    int maxVotes;

    // loop through the forms in the test data
    testForm=testData.begin();
    while ( testForm != testData.end() ) {

        testWordList=forms[*testForm];
        writer=testWordList.front().writer;

        votes.clear();
        maxVotes=0;

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

                    wordSim=(*testWord) * (*trainWord); // calculate similarity between Words
                    if (wordSim > maxSim) {
                        guess=trainWord->writer;
                        maxSim=wordSim;
                    }
                    trainWord++;
                }
                trainForm++;
            }

            if (maxSim >= epsilonMin) {
                totalWord++;
                if (guess == testWord->writer)
                    correctWord++;

                cout << "\t" << "Word " << totalWord << ", " 
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
        totalForm++;

        cout << "Form " << totalForm << ", "
            << 100*((float)correctForm/totalForm) 
            << "% accuracy on form writer, "
            << writer << " => " << bestGuess << "\n";

        voteIt=votes.begin();
        cout << "\t" << "Votes: ";
        while (voteIt != votes.end()) {
            cout << voteIt->first << ": " << voteIt->second << ", ";
            voteIt++;
        }
        cout << "\n";
        testForm++;
    }

    return 0;
}
