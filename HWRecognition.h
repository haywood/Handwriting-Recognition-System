#ifndef HW_RECOG_H_
#define HW_RECOG_H_

#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <iostream>
#include <string>

typedef int WriterId;
typedef std::string FormId;

struct Word {
    std::string filename,
                text;
    cv::Mat_<float> features;
    WriterId writer;
    FormId form;
    double featureNorm;
    int lineNum,
        wordNum;

    inline explicit Word(const std::string &filename, const std::string &text, const cv::Mat_<float> &features, const WriterId &writer, const FormId &form, const int &lineNum, const int &wordNum):
        filename(filename), 
        text(text), 
        features(features), 
        writer(writer), 
        form(form), 
        lineNum(lineNum), 
        wordNum(wordNum)
        { featureNorm=cv::norm(features); }

    inline explicit Word(const Word &w): 
        filename(w.filename), 
        text(w.text), 
        features(w.features), 
        writer(w.writer), 
        form(w.form), 
        featureNorm(w.featureNorm),
        lineNum(w.lineNum), 
        wordNum(w.wordNum)
        {}

    inline const Word& operator = (const Word &w)
    {
        if (this != &w) {
            filename=w.filename;
            text=w.text;
            features=w.features;
            writer=w.writer;
            form=w.form;
            featureNorm=w.featureNorm;
            lineNum=w.lineNum;
            wordNum=w.wordNum;
        }
        return *this;
    }
};

inline float operator * (const Word &word1, const Word &word2)
{
    return sum(word1.features.mul(word2.features))[0]/(word1.featureNorm*word2.featureNorm);
}

#endif /* HW_RECOG_H_ */
