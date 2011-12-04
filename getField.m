function [ fieldValue ] = getField(wordRecord, fieldName)
%Get the field named fieldName from wordRecord
    try
        fieldValue=wordRecord.record.(fieldName);
    catch e
        throw(e);
    end
end

