classdef (Abstract) composite < handle
    %COMPOSITE abstract class for implementing the composite design pattern
    
    methods (Abstract)
        it = createIterator(obj); % Returns an iterator for the collection subclassing the composite
    end
end