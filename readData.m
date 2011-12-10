function wordRecords=readData(perPerson, angles, frequencies, filterSize, windowWidth, blockSize)

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

% Create Gabor filters to be used later

sigma=filterSize/10; % width of Gaussian
gamma=2; % ellipsoidicity of Gaussian

gaborIndex=1;
freqStep=1;

for angle=0:angles-1
    for freq=freqStep:freqStep:freqStep*frequencies
        
        % create a gabor filter using the current set of parameters and
        % save it
        gaborWindow=gbfilter(filterSize, filterSize, angle*180/angles, sigma, gamma, sigma/freq);
        figure(gaborIndex); imshow(gaborWindow/max(gaborWindow(:)));
        gaborWindows(gaborIndex).window=gaborWindow;
        gaborIndex=gaborIndex+1;
        
    end
end


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
windowStep=windowWidth;
wordIndex=1;

for s=gallery
    %try
        originalIm=255-double(imread(filenames{s}, 'png'));
        originalIm=originalIm/max(originalIm(:));
        compressedIm=localdct(originalIm, dctMatrix);
        
        filterStack=struct(); % filter stack for this word
        imWidth=size(compressedIm, 2);
        zeroCols=[];
        zeroRun=1;
        for imColIndex=1:imWidth
            imCol=compressedIm(:, imColIndex);
            if ~zeroRun && all(imCol==0) 
                zeroRun=1;
            elseif zeroRun
                zeroCols=[zeroCols imColIndex-1];    
                zeroRun=0;
            end
        end
        
        for gaborIndex=1:length(gaborWindows)
            
            windowList=struct(); % window this for this filter stack level
            windowIndex=1; % index into the current window number
        
            gaborWindow=gaborWindows(gaborIndex).window;
            
            if windowWidth >= imWidth
                
                windowIm=conv2(gaborWindow, compressedIm, 'same');
                
                if max(windowIm(:)) ~= 0
                    windowIm=windowIm(:)/max(windowIm(:));
                    %windowIm(windowIm < 0.5)=0;
                    %windowIm(windowIm > 0)=1;
                    windowList(windowIndex).numerator=windowIm;
                    windowList(windowIndex).denominator=norm(windowIm);
                end
                
            else
                for leftEdge=1:windowStep:imWidth-windowWidth
                    rightEdge=leftEdge+windowWidth;
                    
                    % create window by convolving with gabor filter
                    windowIm=conv2(gaborWindow, compressedIm(:,leftEdge:rightEdge), 'same');
                    
                    if max(windowIm(:)) ~= 0
                        windowIm=windowIm(:)/max(windowIm(:));
                        %windowIm(windowIm < 0.5)=0;
                        %windowIm(windowIm > 0)=1;
                        windowList(windowIndex).numerator=windowIm;
                        windowList(windowIndex).denominator=norm(windowIm);
                        windowIndex=windowIndex+1; % increment window index
                    end
                    
                end
            end                        
            
            filterStack(gaborIndex).windows=windowList;
        
        end        
        
        wordRecord.im=compressedIm; % store compressed image
        wordRecord.writer=writers(s); % store the writer id
        wordRecord.form=forms{s}; % store the form id
        wordRecord.line=lines(s); % store the line id
        wordRecord.wordid=wordids(s); % store the wordid
        wordRecord.filename=filenames{s}; % store the filename of the image
        wordRecord.word=actualWords{s}; % store the text version of the word
        wordRecord.filterStack=filterStack; % save windows
        
        wordRecords(wordIndex).record=wordRecord;
        wordIndex=wordIndex+1;
    %catch
    %end
end
