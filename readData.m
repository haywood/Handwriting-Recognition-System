function wordRecords=readData(perPerson)

dfile=fopen('data/wordswithwriters.txt', 'r');
D=textscan(dfile, '%d %s %d %d %s %s');
fclose(dfile);

blockSize=14;

dctMatrix=dctmtx(blockSize);

writers=D{1}';
forms=D{2};
lines=D{3}';
wordids=D{4}';
filenames=strcat('data/words/', D{5});
actualWords=D{6};

people=unique(writers);
gallery=[];

for person=people
    theirs=find(writers==person);
    for i=1:perPerson
        form=forms{theirs(i)};
        formWords=find(strcmp(forms, form));
        gallery=[gallery formWords'];
    end
end

wordRecords=struct();
wordRecord=struct();
wordIndex=1;

windowHeight=0;
maxWindowWidth=0;

for s=gallery
    %try
    originalIm=255-double(imread(filenames{s}, 'png'));
    originalIm(find(originalIm<100))=0;
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
    %catch
    %end
end

maxWindowWidth=ceil(0.1*maxWindowWidth);
minWindowWidth=ceil(0.7*maxWindowWidth);
windowWidthIncr=ceil(0.1*maxWindowWidth);

gamma=2;

frequencies=10;
angles=4;

for wordIndex=1:length(wordRecords)
    
    wordIm=wordRecords(wordIndex).record.im; % the full word image
    windowStack=struct(); % at each level, the windows are of a different width
    stackIndex=1; % index into the window stack
    
    for windowWidth=minWindowWidth:windowWidthIncr:maxWindowWidth % vary the window width
        
        windowStack(stackIndex).windows=struct(); % initialize the list for this window width
        
        sigma=windowWidth/10; % set up sigma for this window width
        
        windowIndex=1; % index into the window list
        
        for column=1:windowWidth:size(wordIm, 2) % move the window through the image
            
            c=min([column+windowWidth-1 size(wordIm, 2)]); % make sure there is no index error
            
            windowIm=zeros(windowHeight,windowWidth); % initialize an image to store the window
            
            for i=0:angles-1
                for k=0:frequencies-1
                    
                    % create a gabor filter for the window using the
                    % current set of parameters
                    gaborWindow=gbfilter(windowHeight, windowWidth, i*180/angles, sigma, gamma, sigma/(k+1));
                    
                    convolutionResult=conv2(gaborWindow, wordIm(:, column:c), 'same');
                    
                    % create the window as the superposition of the different convolutions
                    windowIm=windowIm+convolutionResult;
                end
            end
            
            if max(windowIm(:)) ~= 0 % check that there is something in the window
                
                % store and normalize the window
                windowStack(stackIndex).windows(windowIndex).window=windowIm/max(windowIm(:));
                windowIndex=windowIndex+1;
            end
            
        end
        stackIndex=stackIndex+1;
    end
    
    wordRecords(wordIndex).record.windowStack=windowStack;
end