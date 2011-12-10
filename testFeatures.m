function [guess,writers]=testFeatures(perPerson)

%test the features to see how well they discriminate between writers based
%on single words

words=readData(perPerson)

totalData=1:length(words);
probe=find(mod(totalData-1, perPerson)==0);
gallery=setdiff(totalData, probe);

guess=zeros(1,length(probe));
writers=zeros(1,length(guess));

figure(1); imshow(getField(words(4), 'im'));

fprintf('Number of probes: %d\n', length(probe));
fprintf('Number of gallery: %d\n', length(gallery));

assert(isempty(intersect(probe,gallery)));

for i=1:length(probe)

    testWord=words(probe(i));
    best=-1;
    guessi=0;
    traini=0;
    
    for j=gallery
        
        trainWord=words(j);
        
        s=wordRecordSimilarity(testWord, trainWord);

        if s > best
            best = s;
            guessi=getField(trainWord, 'writer');
            traini=j;
        end
        
    end
    
    guess(i)=guessi;
    writers(i)=getField(testWord, 'writer');
    
    fprintf('Test %d, %f%% correct %d => %d with similarity %f on word %d\n', i, 100*sum(guess(1:i)==writers(1:i))/i, writers(i), guess(i), best, traini);
end

fprintf('Percent correct: %f\n', 100*sum(guess==writers)/length(guess));