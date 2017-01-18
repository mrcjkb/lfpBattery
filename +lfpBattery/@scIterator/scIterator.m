classdef scIterator < lfpBattery.iterator
    %SCITERATOR iterator for the sortedCollection class and it's subclasses
    %
    %SEE ALSO lfpBattery.iterator
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %January 2017
    
    properties (SetAccess = 'immutable', GetAccess = 'protected')
      collection;  % The elements the iterator traverses through
    end
    properties (Access = 'protected')
        ind = 0;  % index of collection's next item
    end
    methods
        function it = scIterator(scObj)
            it.collection = scObj;
        end
        function obj = next(it)
            if hasNext(it)
                it.ind = it.ind + 1;
                disp(it.ind)
                obj = it.collection.xydata(it.ind);
            else
                obj = [];
            end
        end
        function tf = hasNext(it)
            tf = numel(it.collection.xydata) > it.ind;
        end
        function reset(it)
            it.ind = 0;
        end
    end
    
end

