function [ wordSim ] = wordRecordSimilarity(wordRecord1, wordRecord2)

% Compute the wordSim of two word records
% Similarity is computed as an average of
% cross-correlation results over the window sets of the two word records

windowList1=getField(wordRecord1, 'windowList');
windowList2=getField(wordRecord2, 'windowList');
simArray=[];


for wIndex1=1:length(windowList1)
    
    window1=windowList1(wIndex1).window;

    if max(window1(:)) ~= 0
    
        for wIndex2=1:length(windowList2)
            
            window2=windowList2(wIndex2).window;
            windowSim=-1;
            
            if max(window2(:)) ~= 0
                windowSim=max([windowSim corr2(window1, window2)]);
            end
            
            if windowSim >= 0
                simArray=[simArray windowSim];
            end
            
        end
    
    end
    
end

wordSim=mean(simArray);