function [ similarity ] = wordRecordSimilarity(wordRecord1, wordRecord2)

% Compute the similarity of two word records
% Similarity is computed as an average of
% cross-correlation results over the window sets of the two word records

similarity=0;
total=0;

windowStack1=getField(wordRecord1, 'windowStack');
windowStack2=getField(wordRecord2, 'windowStack');

stackSize=length(windowStack1);

for windowLevel=1:stackSize % go through window width levels
    
    windowList1=windowStack1(windowLevel).windows;
    windowList2=windowStack2(windowLevel).windows;
    
    for wIndex1=1:length(windowList1) % go through first window list
        
        window1=windowList1(wIndex1).window;
        
        if max(window1(:)) ~= 0 % avoid divide by zero in corr2
            
            for wIndex2=1:length(windowList2) % go through second window list
                
                window2=windowList2(wIndex2).window;
                
                if max(window2(:)) ~= 0 % avoid divide by zero in corr2
                    
                    s=abs(corr2(window1, window2));
                    similarity=similarity+s;
                    total=total+1;
                    
                end
            end
        end
    end    
end

assert(~isnan(similarity));
if total ~= 0 similarity=similarity/total; end