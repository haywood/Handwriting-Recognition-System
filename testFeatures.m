function [guess,writers]=testFeatures(perPerson)

%test the features to see how well they discriminate between writers based
%on single words

words=readData(perPerson, 3, 3, 24, 10, 8);

totalData=1:length(words);
probe=find(mod(totalData-1, perPerson)==0);
gallery=setdiff(totalData, probe);
writerSet=[];
for word=words
    writerSet=[writerSet getField(word, 'writer')];
end
writerSet=unique(writerSet);

guess=zeros(1,length(probe));
writers=zeros(1,length(guess));

figure; imshow(getField(words(4), 'im'));

fprintf('Number of probes: %d\n', length(probe));
fprintf('Number of gallery: %d\n', length(gallery));

assert(isempty(intersect(probe,gallery)));

for i=1:length(probe)

    testWord=words(probe(i));
    writerSim=zeros(2,length(writerSet));
    
    for j=gallery
        
        trainWord=words(j);
        
        s=wordRecordSimilarity(testWord, trainWord);
        
        trainWriter=getField(trainWord, 'writer');        
        writerIndex=find(writerSet == trainWriter);
        
        writerSim(1, writerIndex)=writerSim(1, writerIndex)+s;
        writerSim(2, writerIndex)=writerSim(2,writerIndex)+1;

    end
    
    writerSim=writerSim(1,:)./writerSim(2,:);
    [s, guessi]=max(writerSim);
    guess(i)=writerSet(guessi);
    writers(i)=getField(testWord, 'writer');
    
    fprintf('Test %d, %f%% correct %d => %d with similarity %f\n', i, 100*sum(guess(1:i)==writers(1:i))/i, writers(i), guess(i), s);
end

fprintf('Percent correct: %f\n', 100*sum(guess==writers)/length(guess));