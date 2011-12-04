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
    length(gallery)
    wordIndex=1;
            
    windowHeight=0;
    maxWindowWidth=0;
    
    for s=gallery
        %try            
            im=255-double(imread(filenames{s}, 'png'));
            im(find(im<100))=0;
            im=im/max(im(:));

            wordRecord.orig=im;
            
            im=localdct(im, dctMatrix);            
            wordRecord.im=im;
            
            wordRecord.writer=writers(s);
            wordRecord.form=forms{s};
            wordRecord.line=lines(s);
            wordRecord.wordid=wordids(s);
            wordRecord.filename=filenames{s};
            wordRecord.word=actualWords{s};
            
            if size(im, 1)>windowHeight windowHeight=size(im, 1); end
            if size(im, 2)>maxWindowWidth maxWindowWidth=size(im, 2); end
            
            wordRecords(wordIndex).record=wordRecord;
            wordIndex=wordIndex+1;
        %catch
        %end
    end

    maxWindowWidth=ceil(0.1*maxWindowWidth);
    minWindowWidth=ceil(0.7*maxWindowWidth);
    windowWidthIncr=ceil(0.1*maxWindowWidth);
    
    [windowHeight maxWindowWidth]
    length(wordRecords)
    
    figure(1); imshow(wordRecords(1).record.orig/max(wordRecords(1).record.orig(:)));

    gamma=2;
    
    frequencies=4;
    angles=10;
    
    for wordIndex=1:length(wordRecords)        
        
        wordIm=wordRecords(wordIndex).record.im;
        windowStack=struct();
        stackIndex=1;
        
        for windowWidth=minWindowWidth:windowWidthIncr:maxWindowWidth
            
            windowStack(stackIndex).windows=struct();
        
            sigma=windowWidth/10;

            gaborWindow=gbfilter(windowHeight, windowWidth, 0, 1, gamma, sigma);
            windowIndex=1;
            
            for column=1:windowWidth:size(wordIm, 2)
            
                c=min([column+windowWidth-1 size(wordIm, 2)]);
                
                im=zeros(windowHeight,windowWidth);
                for i=0:angles-1
                    for k=0:frequencies-1
                        gb=gbfilter(windowHeight, windowWidth, i*180/angles, sigma, gamma, sigma/(k+1));
                        p=conv2(gaborWindow, wordIm(:, column:c), 'same');
                        im=im+p;
                    end
                end
                                           
                windowStack(stackIndex).windows(windowIndex).window=im;
                windowIndex=windowIndex+1;
                
            end
            stackIndex=stackIndex+1;
        end
        
        wordRecords(wordIndex).record.windowStack=windowStack;
    end
    
    size(wordRecords(1).record.windowStack)
    size(wordRecords(1).record.windowStack(1).windows)
    fignum=1;
    for i=1:length(wordRecords(1).record.windowStack)
        for j=1:length(wordRecords(1).record.windowStack(i).windows)
            im=wordRecords(1).record.windowStack(i).windows(j).window;
            fignum=fignum+1;
            figure(fignum); imshow(im/max(im(:)));
        end
    end
    
    %{
    S=zeros(length(f));
    validate=unique(1+floor(rand(1,ceil(0.1*sampleSize))*length(f)));
    train=setdiff(1:length(f),validate);
        
    for i=validate
        best=-inf;
        k=0;
        for j=train
            if i~=j
                s=0;
                for windowIndex=1:length(gbf(i).windowStack)
                    
                    windowListValidate=gbf(i).windowStack(windowIndex).windows;
                    windowListTrain=gbf(j).windowStack(windowIndex).windows;
                    
                    for r=1:length(windowListValidate)
                        for c=1:length(windowListTrain)
                            s=s+abs(corr2(windowListValidate(r).window, windowListTrain(c).window));
                        end
                    end
                end
                if s > best
                    best=s;
                    k=j;
                end
            end
        end
        if k>0
            guess(i)=f(k).writer;
        else
            guess(i)=-1;
        end
    end
    success=100*sum([f(validate).writer]==guess(validate))/length(validate)
    %}