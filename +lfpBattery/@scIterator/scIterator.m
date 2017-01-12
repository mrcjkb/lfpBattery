classdef scIterator < lfpBattery.iterator
    %SCITERATOR iterator for the sortedCollection class and it's subclasses
    %
    %SEE ALSO lfpBattery.iterator
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %January 2017
    
    properties (Access = 'protected', Hidden = true)
        ind = 0;  % index of collection's next item
    end
    methods
        function it = scIterator(scObj)
            it@lfpBattery.iterator(scObj); % call superclass constructor
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

