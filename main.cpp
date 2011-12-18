#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <iostream>
#include <fstream>
#include <cassert>
#include <list>
#include <map>
#include <set>

#include "HWRecognition.h"

using namespace std;
using namespace cv;

size_t getOptimalDCTSize(size_t N) { return 2*getOptimalDFTSize((N+1)/2); }

int main(int argc, char **argv)
{
    if (argc != 6) {
        cerr << "usage: " << argv[0] << " <dataDir>\n";
        return 0;
    }

    string dataDir(argv[1]), wordsDir=dataDir+"/words/"; 
    string indexFilename=dataDir+"/wordswithwriters.txt"; 
    string imFilename, text;

    int transformScale=atoi(argv[2]);
    int featureHeight=atoi(argv[3]), featureWidth=atoi(argv[4]);
    int perWriter=atoi(argv[5]);
    int transformRows, transformCols;
    int lineNum, wordNum;

    Mat img, padded, transform, features;
    ifstream indexFile(indexFilename.c_str());

    Size transformSize(transformScale, transformScale);
    WriterId writer;
    FormId form;

    map <WriterId, list<Word *> > trainData;
    map <FormId, list<Word *> >  testData;
    map <WriterId, int> formCounts;
    set <FormId> formSet;
    list<Word> words;

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

        if (formSet.count(form) || formCounts[writer] < perWriter) {

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
                words.push_back(record);

                // record and count new form
                if (!formSet.count(form)) {
                    formSet.insert(form);
                    formCounts[writer]++;
                }

                // perform separation of training and testing data
                if (trainData.count(writer)) {
                    if (testData.count(form)) {
                        testData[form].push_back(&words.back());
                    } else {
                        trainData[writer].push_back(&words.back());
                    }
                } else {
                    testData[form].push_back(&words.back());
                    trainData[writer];
                }
            }
        }
    }

    cout << "Read in " << words.size() << " words\n";

    map<WriterId, list<Word *> >::iterator writerIt;
    map<FormId, list<Word *> >::iterator formIt;
    list<Word *>::iterator testWord, trainWord;
    list<Word *> formWords, writerWords;
    map<WriterId, int> votes;
    Mat_<float> wordSim;
    float maxSim;
    WriterId guess, bestGuess;
    int correctForm=0;
    int correctWord=0; 
    int totalWord=0;
    int maxVotes;

    // loop through the forms in the test data
    for (formIt=testData.begin(); formIt != testData.end(); ++formIt) {

        formWords=formIt->second;
        writer=formWords.front()->writer;

        votes.clear();
        maxVotes=0;

        // loop through words in the form
        for (testWord=formWords.begin(); testWord != formWords.end(); ++testWord) {

            maxSim=0.0f;

            // loop through writers in the train data
            for (writerIt=trainData.begin(); writerIt != trainData.end(); ++writerIt) {
                
                writerWords=writerIt->second;
                
                // loop through words in the writer
                for (trainWord=writerWords.begin(); trainWord != writerWords.end(); ++trainWord) {
                    matchTemplate((*testWord)->features, (*trainWord)->features, wordSim, CV_TM_CCORR_NORMED);
                    if (wordSim.at<float>(0,0) > maxSim) {
                        maxSim=wordSim.at<float>(0, 0);
                        guess=(*trainWord)->writer;
                    }
                }
            }

            totalWord++;
            if (guess == (*testWord)->writer)
                correctWord++;

            cout << "Word " << totalWord << ", " << 100*((float)correctWord/totalWord) << "% success, "
                << (*testWord)->writer << " => " << guess << ", " << "with similarity " << maxSim << "\n";

            votes[guess]++;
            if (votes[guess] > maxVotes) {
                maxVotes=votes[guess];
                bestGuess=guess;
            }
        }

        if (bestGuess == writer) correctForm++;
    }

    cout << 100*((float)correctForm/testData.size()) << "% accuracy on writing sample author.\n";

    return 0;
}
