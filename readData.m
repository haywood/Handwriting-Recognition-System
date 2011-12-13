function [wordRecords]=readData(perPerson, filterSize, blockSize)

% read the word data from the image files,
% taking perPerson number of forms for each writer
% return a word record structure array

if perPerson < 1 || perPerson > 10
    throw(MException('readData:OutOfRange', 'perPerson must be an integer between 1 and 10.'));
end

dfile=fopen('data/wordswithwriters.txt', 'r');
D=textscan(dfile, '%d %s %d %d %s %s');
fclose(dfile);

dctMatrix=dctmtx(blockSize); % DCT matrix for compression

writers=D{1}';
forms=D{2}';
lines=D{3}';
wordids=D{4}';
filenames=strcat('data/words/', D{5});
actualWords=D{6};

people=unique(writers);
gallery=[];

for person=people
    theirForms=unique(forms(writers==person));
    theirForms=theirForms(1:perPerson);
    for form=theirForms
        formIndicies=find(strcmp(forms, form));
        gallery=[gallery formIndicies];
    end
end

wordRecords=struct();
wordRecord=struct();
wordIndex=1;

for s=gallery
    try
        originalIm=255-double(imread(filenames{s}, 'png'));
        originalIm=originalIm/max(originalIm(:));
        compressedIm=localdct(originalIm, dctMatrix);

        dctHeight=max(filterSize, size(compressedIm, 1));
        dctWidth=max(filterSize, size(compressedIm, 2));
        
        windowIm=dct2(compressedIm, dctHeight, dctWidth);
        windowIm=windowIm(1:filterSize, 1:filterSize);
        windowIm=windowIm/max(abs(windowIm(:)));

        wordRecord.im=originalIm; % store original image
        wordRecord.numerator=windowIm; % store window
        if max(windowIm(:)) ~= 0
            wordRecord.denominator=norm(windowIm(:));
        else
            wordRecord.denominator=1;
        end
        wordRecord.writer=writers(s); % store the writer id
        wordRecord.form=forms{s}; % store the form id
        wordRecord.line=lines(s); % store the line id
        wordRecord.wordid=wordids(s); % store the wordid
        wordRecord.filename=filenames{s}; % store the filename of the image
        wordRecord.word=actualWords{s}; % store the text version of the word
        
        wordRecords(wordIndex).record=wordRecord;
        wordIndex=wordIndex+1;
    catch
    end
end
