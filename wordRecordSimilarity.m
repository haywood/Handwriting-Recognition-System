function [wordSim] = wordRecordSimilarity(wordRecord1, wordRecord2)

% Compute the wordSim of two word records
% Similarity is computed as an average of
% cross-correlation results over the window sets of the two word records

num1=getField(wordRecord1, 'numerator');
num2=getField(wordRecord2, 'numerator');
den1=getField(wordRecord1, 'denominator');
den2=getField(wordRecord2, 'denominator');

wordSim=sum(num1(:).*num2(:))/(den1*den2);
