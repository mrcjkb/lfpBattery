classdef scIterator < lfpBattery.iterator
    %SCITERATOR iterator for the sortedFunctions class and it's subclasses
    %
    %SCITERATOR Methods:
    %    next    - Returns next object.
    %    hasNext - Returns true if there is another object to iterate
    %              through
    %    reset   - Resets iterator to first object
    %
    %SEE ALSO lfpBattery.iterator
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %January 2017
    
    properties (SetAccess = 'immutable', GetAccess = 'protected')
      collection@lfpBattery.sortedFunctions;  % The elements the iterator traverses through
    end
    properties (Access = 'protected')
        ind@uint32 scalar = 0;  % index of collection's next item
    end
    
    methods
        function it = scIterator(scObj)
            it.collection = scObj;
        end
        function obj = next(it)
            if hasNext(it)
                it.ind = it.ind + 1;
                obj = it.collection(it.ind);
            else
                obj = [];
            end
        end
        function tf = hasNext(it)
            tf = numel(it.collection) > it.ind;
        end
        function reset(it)
            it.ind = 0;
        end
    end
    
end

