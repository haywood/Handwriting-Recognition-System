function testFeatures(perPerson, filterSize, blockSize)

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

% get first of each writer's forms as testing data
[testWriters,testIndices,testForms]=unique(formWriters(2,:));
testForms=formSet(testIndices); % record the testing forms

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

fprintf('Total number of words: %d\n', length(words));
fprintf('Number of probes: %d\n', length(probe));
fprintf('Number of gallery: %d\n', length(gallery));

assert(isempty(intersect(probe,gallery)));

formToWriter=zeros(length(testForms), length(writerSet));

for i=1:length(probe)

    testWord=words(probe(i));
    maxIndex=0;
    maxSim=-inf;
    
    for j=gallery
        
        trainWord=words(j);
        
        writerSim=wordRecordSimilarity(testWord, trainWord);
        
        if writerSim > maxSim
            trainWriter=getField(trainWord, 'writer');        
            writerIndex=find(writerSet == trainWriter);
            maxIndex=writerIndex;
            maxSim=writerSim;
        end

    end
    
    % get current test form
    form=getField(testWord, 'form');
    formIndex=find(strcmp(testForms, form));

    % update form to writer similarity
    formToWriter(formIndex, maxIndex)=formToWriter(formIndex, maxIndex)+1;

    guess(i)=writerSet(maxIndex);
    writers(i)=getField(testWord, 'writer');
    
    fprintf('Test %d, %f%% correct %d => %d with similarity %f\n', i, 100*sum(guess(1:i)==writers(1:i))/i, writers(i), guess(i), maxSim);
end

% record maximally similar writers
[s,k]=max(formToWriter, [], 2);
testGuess=writerSet(k);

formAcc=100*sum(testGuess==testWriters)/length(testGuess);
wordAcc=100*sum(guess==writers)/length(guess);

fprintf('Percent forms correct: %f\n', formAcc);
fprintf('Percent words correct: %f\n', wordAcc);
