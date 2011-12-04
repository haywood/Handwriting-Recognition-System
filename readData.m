function wordRecords=readData(perPerson)

% read the word data from the image files,
% taking perPerson number of forms for each writer
% return a word record structure array

dfile=fopen('data/wordswithwriters.txt', 'r');
D=textscan(dfile, '%d %s %d %d %s %s');
fclose(dfile);

blockSize=14;

dctMatrix=dctmtx(blockSize);

writers=D{1}';
forms=D{2}';
lines=D{3}';
wordids=D{4}';
filenames=strcat('data/words/', D{5});
actualWords=D{6};

people=unique(writers);
gallery=[];

for person=people
    theirForms=forms(writers==person);
    theirForms=theirForms(1:perPerson);
    for form=theirForms
        formIndicies=find(strcmp(forms, form));
        gallery=[gallery formIndicies];
    end
end

wordRecords=struct();
wordRecord=struct();
wordIndex=1;

windowHeight=0;
maxWindowWidth=0;

for s=gallery
    originalIm=255-double(imread(filenames{s}, 'png'));
    originalIm(originalIm(:)<100)=0;
    originalIm=originalIm/max(originalIm(:));
    compressedIm=localdct(originalIm, dctMatrix);
    
    wordRecord.orig=originalIm; % store original image
    wordRecord.im=compressedIm; % store compressed image
    wordRecord.writer=writers(s); % store the writer id
    wordRecord.form=forms{s}; % store the form id
    wordRecord.line=lines(s); % store the line id
    wordRecord.wordid=wordids(s); % store the wordid
    wordRecord.filename=filenames{s}; % store the filename of the image
    wordRecord.word=actualWords{s}; % store the text version of the word
    wordRecord.windowStack=struct(); % initialize the window stack
    
    if size(compressedIm, 1)>windowHeight windowHeight=size(compressedIm, 1); end
    if size(compressedIm, 2)>maxWindowWidth maxWindowWidth=size(compressedIm, 2); end
    
    wordRecords(wordIndex).record=wordRecord;
    wordIndex=wordIndex+1;
end

maxWindowWidth=ceil(0.1*maxWindowWidth);
minWindowWidth=ceil(0.7*maxWindowWidth);
windowWidthIncr=ceil(0.1*maxWindowWidth);

gamma=2;

frequencies=10;
angles=4;

windowLevel=1; % index into the window stack for this width level
    
for windowWidth=minWindowWidth:windowWidthIncr:maxWindowWidth % vary the window width
    
    sigma=windowWidth/10; % set up sigma for this window width
    gaborWindows=struct(); % set up a struct for this level's gabor windows
    gaborIndex=1;
    
    for i=0:angles-1
        for k=0:frequencies-1
            
            % create a gabor filter using the current set of parameters and
            % save it
            gaborWindow=gbfilter(windowHeight, windowWidth, i*180/angles, sigma, gamma, sigma/(k+1));
            gaborWindows(gaborIndex).window=gaborWindow;
            gaborIndex=gaborIndex+1;
            
        end
    end
    
    
    for wordIndex=1:length(wordRecords) % create windows for each word record
        
        wordIm=getField(wordRecords(wordIndex), 'im'); % the full word image
        
        windows=struct(); % initialize a window list for this word record        
        
        windowIndex=1; % index into the window list
        
        for column=1:windowWidth:size(wordIm, 2) % move the window through the image
            
            c=min([column+windowWidth-1 size(wordIm, 2)]); % make sure there is no index error
            
            wordPiece=wordIm(:, column:c); % get the current piece of the word image
            
            windowIm=zeros(windowHeight,windowWidth); % initialize an image to store the window
            
            for gaborIndex=1:length(gaborWindows) % convolve the this portion of the word with the gabor filters
                
                gaborWindow=gaborWindows(gaborIndex).window;
                
                convolutionResult=conv2(gaborWindow, wordPiece, 'same');
                
                % superimpose the convolutions to form the window
                windowIm=windowIm+convolutionResult;
                
            end
            
            if max(windowIm(:)) ~= 0 % check that there is something in the window
                
                % store and normalize the window
                windows(windowIndex).window=windowIm/max(windowIm(:));
                windowIndex=windowIndex+1;
                
            end
            
        end
        
        wordRecords(wordIndex).record.windowStack(windowLevel).windows=windows;
    
    end
    
    windowLevel=windowLevel+1;

end