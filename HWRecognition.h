#include <opencv2/core/core.hpp>
#include <string>

typedef int WriterId;
typedef std::string FormId;

struct Word {
    std::string filename,
                text;
    cv::Mat_<float> features;
    WriterId writer;
    FormId form;
    int lineNum,
        wordNum;

    Word(std::string filename, std::string text, cv::Mat_<float> features, WriterId writer, FormId form, int lineNum, int wordNum):
        filename(filename), 
        text(text), 
        features(features), 
        writer(writer), 
        form(form), 
        lineNum(lineNum), 
        wordNum(wordNum)
        {}

    Word(const Word &w): 
        filename(w.filename), 
        text(w.text), 
        features(w.features), 
        writer(w.writer), 
        form(w.form), 
        lineNum(w.lineNum), 
        wordNum(w.wordNum)
        {}

    const Word& operator = (const Word &w)
    {
        if (this != &w) {
            filename=w.filename;
            text=w.text;
            features=w.features;
            writer=w.writer;
            form=w.form;
            lineNum=w.lineNum;
            wordNum=w.wordNum;
        }
        return *this;
    }
};
