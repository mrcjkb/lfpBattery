classdef nullIterator < lfpBattery.iterator
    %NULLITERATOR iterator for leaf elements of a composite pattern.
    %Each method returns an empty variable
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         January 2017
    
    methods
        function obj = next(it)
            obj = [];
        end
        function tf = hasNext(it)
            tf = false;
        end
        function reset(it) %#ok<*MANU>
        end
    end
    
end

