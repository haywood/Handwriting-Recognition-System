function [ wordSim ] = wordRecordSimilarity(wordRecord1, wordRecord2)

% Compute the wordSim of two word records
% Similarity is computed as an average of
% cross-correlation results over the window sets of the two word records

wordSim=0;
total=0;

widthList1=getField(wordRecord1, 'widthList');
widthList2=getField(wordRecord2, 'widthList');

numWidths=length(widthList1);
numGabors=length(widthList1(1).level);

figure(1); imshow(getField(wordRecord1, 'orig'));
figure(2); imshow(getField(wordRecord2, 'orig'));

for widthIndex=1:numWidths
    
    gaborList1=widthList1(widthIndex).level;
    gaborList2=widthList2(widthIndex).level;
    
    for gaborIndex=1:numGabors
        
        windowList1=gaborList1(gaborIndex).windows;
        windowList2=gaborList2(gaborIndex).windows;
        
        for wIndex1=1:length(windowList1)
            
            window1=windowList1(wIndex1).window;
            
            windowSim=-1;
                
            if max(window1(:)) ~= 0
                
                for wIndex2=1:length(windowList2)
                    
                    window2=windowList2(wIndex2).window;
                    
                    if max(window2(:)) ~= 0
                        
                        windowSim=max([windowSim corr2(window1, window2)]);
                        
                    end
                    
                end
                
            end
            
            if windowSim >= 0
                wordSim=wordSim+windowSim;
                total=total+1;
            end

        end
        
    end
end

if total ~= 0 wordSim=wordSim/total; end