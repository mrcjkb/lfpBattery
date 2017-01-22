classdef vIterator < lfpBattery.iterator
    %VITERATOR: Iterator for iterating through vectors using the
    %lfpBattery.iterator interface.
    %
    %SEE ALSO: lfpBattery.iterator
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         January 2017
    
    properties (SetAccess = 'immutable', GetAccess = 'protected')
        collection;  % The elements the iterator traverses through
    end
    properties (Access = 'protected')
        ind = uint32(0);  % index of collection's next item
    end
    
    methods
        function it = vIterator(v)
            it.collection = v;
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

