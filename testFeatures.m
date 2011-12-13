function [guess,writers]=testFeatures(perPerson, perTrain, filterSize, blockSize)

% test the features to see how well they discriminate between writers based
% on single words

words=readData(perPerson, filterSize, blockSize);
totalData=1:length(words);
writerList=[];
formList={};

for word=words
    writerList=[writerList getField(word, 'writer')];
    formList{end+1}=getField(word, 'form');
end

% get unique lists of writers and forms
writerSet=unique(writerList);
formSet=unique(formList);

formWriters=zeros(2,length(formSet)); % track who wrote each form in formSet
for i=1:length(formSet)
    formIndex=find(strcmp(formList, formSet{i}));
    formWriters(2, i)=writerList(formIndex(1));
end

testWriters=[];
testIndices=[];

writerCounts=zeros(1,length(writerSet));

% get first half of each writer's forms as testing data
for i=1:size(formWriters, 2)
    writer=formWriters(2,i);
    writerIndex=find(writerSet==writer);
    if writerCounts(writerIndex) < perPerson-perTrain
        testIndices=[testIndices i];
        testWriters=[testWriters writer];
        writerCounts(writerIndex)=writerCounts(writerIndex)+1;
    end
end

testForms=formSet(testIndices); % record the testing forms
trainIndices=setdiff(1:length(formSet),testIndices); % record the training forms

% split words up into probe and gallery by index
gallery=[];
probe=[];
for i=totalData
    form=formList{i};
    if any(strcmp(testForms, form))
        probe=[probe i];
    else
        gallery=[gallery i];
    end
end

% set up guess and correct
guess=zeros(1,length(probe));
writers=zeros(1,length(guess));

fprintf('Number of probes: %d\n', length(probe));
fprintf('Number of gallery: %d\n', length(gallery));

assert(isempty(intersect(probe,gallery)));

i=1;
for word=words
    wordWriter=getField(word, 'writer');
    if find(writerSet==wordWriter)==i
        wordIm=getField(word, 'im');
        wordIm=imresize(wordIm, [100 100]);
        wordIm=wordIm/max(wordIm(:));
        wordIm=dct2(wordIm);
        figure(i); imshow(wordIm);
        i=i+1;
        if i > length(writerSet) break; end
    end
end

formToWriter=zeros(length(testForms), length(writerSet));

for i=1:length(probe)

    testWord=words(probe(i));
    writerSim=zeros(1,length(writerSet));
    
    for j=gallery
        
        trainWord=words(j);
        
        s=wordRecordSimilarity(testWord, trainWord);
        
        trainWriter=getField(trainWord, 'writer');        
        writerIndex=find(writerSet == trainWriter);
        
        writerSim(writerIndex)=max(writerSim(writerIndex), s);

    end
    
    [s, guessi]=max(writerSim);

    % get current test form
    form=getField(testWord, 'form');
    formIndex=find(strcmp(testForms, form));

    % update form to writer similarity
    formToWriter(formIndex, guessi)=formToWriter(formIndex, guessi)+1;

    guess(i)=writerSet(guessi);
    writers(i)=getField(testWord, 'writer');
    
    fprintf('Test %d, %f%% correct %d => %d with similarity %f\n', i, 100*sum(guess(1:i)==writers(1:i))/i, writers(i), guess(i), s);
end

% record maximally similar writers
[s,k]=max(formToWriter, [], 2);
testGuess=writerSet(k);

testGuess
testWriters
100*sum(testGuess==testWriters)/length(testGuess)

fprintf('Percent correct: %f\n', 100*sum(guess==writers)/length(guess));
