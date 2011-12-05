function wordRecords=readData(perPerson)

% read the word data from the image files,
% taking perPerson number of forms for each writer
% return a word record structure array

if perPerson < 1 || perPerson > 10
    throw(MException('readData:OutOfRange', 'perPerson must be an integer between 1 and 10.'));
end

dfile=fopen('data/wordswithwriters.txt', 'r');
D=textscan(dfile, '%d %s %d %d %s %s');
fclose(dfile);

blockSize=12;

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

windowHeight=0;
maxWindowWidth=0;

for s=gallery
    try
        originalIm=255-double(imread(filenames{s}, 'png'));
        originalIm=originalIm/max(originalIm(:));
        compressedIm=localdct(originalIm, dctMatrix);
        
        wordRecord.im=compressedIm; % store compressed image
        wordRecord.writer=writers(s); % store the writer id
        wordRecord.form=forms{s}; % store the form id
        wordRecord.line=lines(s); % store the line id
        wordRecord.wordid=wordids(s); % store the wordid
        wordRecord.filename=filenames{s}; % store the filename of the image
        wordRecord.word=actualWords{s}; % store the text version of the word
        wordRecord.widthList=struct(); % initialize the window stack
        
        if size(compressedIm, 1)>windowHeight windowHeight=size(compressedIm, 1); end
        if size(compressedIm, 2)>maxWindowWidth maxWindowWidth=size(compressedIm, 2); end
        
        wordRecords(wordIndex).record=wordRecord;
        wordIndex=wordIndex+1;
    catch
    end
end

maxWindowWidth=ceil(0.1*maxWindowWidth);
minWindowWidth=ceil(0.7*maxWindowWidth);
windowWidthIncr=ceil(0.1*maxWindowWidth);

gamma=2;

frequencies=1;
angles=1;

widthIndex=1; % index into the current width level

for windowWidth=maxWindowWidth:windowWidthIncr:maxWindowWidth % vary the window width
    
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
    
    for wordIndex=1:length(wordRecords)
        
        wordIm=getField(wordRecords(wordIndex), 'im'); % get compressed word image
        gaborList=struct(); % setup empty Gabor list
        
        for gaborIndex=1:length(gaborWindows)
            
            gaborWindow=gaborWindows(gaborIndex).window;
            
            windowIndex=1; % index into the current window number
            windowList=struct(); % setup empty window list
            
            for leftEdge=1:windowWidth:size(wordIm, 2)
                
                rightEdge=min([leftEdge+windowWidth size(wordIm, 2)]); % find right edge of word image slice
                wordPiece=wordIm(:,leftEdge:rightEdge); % extract slice of word image
                windowIm=conv2(gaborWindow, wordPiece, 'same'); % create window by convolving with gabor filter
                if max(windowIm(:)) ~= 0
                    windowList(windowIndex).window=windowIm/max(windowIm(:)); % save image window
                    windowIndex=windowIndex+1; % increment window index
                end
                
            end
            
            gaborList(gaborIndex).windows=windowList; % save window list
        end
        
        wordRecords(wordIndex).record.widthList(widthIndex).level=gaborList; % save width level
        
    end
    
    widthIndex=widthIndex+1; % increment width index
    
end