classdef nullIterator < lfpBattery.iterator
    %NULLITERATOR iterator for leaf elements of a composite pattern.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         January 2017
    
    properties (Hidden, Access = protected)
        object;
        hasnext = true;
    end
    methods
        function it = nullIterator(obj)
            it.object = obj;
        end
        function obj = next(it)
            if it.hasNext
                obj = it.object;
                it.hasnext = false;
            end
        end
        function tf = hasNext(it)
            tf = it.hasnext;
        end
        function reset(it)
            it.hasnext = true;
        end
    end
    
end

