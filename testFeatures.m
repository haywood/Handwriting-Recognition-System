function [guess,writers]=testFeatures(perPerson)

%test the features to see how well they discriminate between writers based
%on single words

words=readData(perPerson)

totalData=1:length(words);
probe=find(mod(totalData-1, perPerson)==0);
gallery=setdiff(totalData, probe);

guess=zeros(1,length(probe));
writers=zeros(1,length(guess));

fprintf('Number of probes: %d\n', length(probe));
fprintf('Number of gallery: %d\n', length(gallery));

for i=1:length(probe)

    testWord=words(probe(i));
    mostSimilar=[-1 0];
    
    for j=gallery
        
        trainWord=words(j);
        
        s=wordRecordSimilarity(testWord, trainWord);
        
        if s > mostSimilar(1)
            mostSimilar = [s getField(trainWord, 'writer')];
        end
        
    end
    
    guess(i)=mostSimilar(2);
    writers(i)=getField(testWord, 'writer');
    
    fprintf('Test %d, %f%% correct\n', i, 100*sum(guess(1:i)==writers(1:i))/i);
end

fprintf('Percent correct: %f\n', 100*sum(guess==writers)/length(guess));