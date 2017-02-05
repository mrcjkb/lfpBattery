classdef batteryIterator < lfpBattery.iterator
    %BATTERYITERATOR: Iterates through a composite battery object's
    %elements and returns the cells (leaf objects).
    %
    %BATTERYITERATOR Methods:
    %    next    - Returns next object.
    %    hasNext - Returns true if there is another object to iterate
    %              through
    %    reset   - Resets iterator to first object
    %
    %To create a batteryIterator object, use the battery's createIterator()
    %method.
    %
    %it = bobj.createIterator;
    %
    %To iterate through the object's cells, use the following syntax:
    %
    %while(it.hasNext)
    %   cell = it.next;
    %   % more code here
    %end
    %
    %Note that a batteryCell will return a nullIterator object.
    %
    %SEE ALSO: lfpBattery.iterator lfpBattery.batteryPack lfpBattery.batteryCell
    %          lfpBattery.batCircuitElement lfpBattery.seriesElement
    %          lfpBattery.seriesElementPE lfpBattery.seriesElementAE
    %          lfpBattery.parallelElement lfpBattery.simplePE
    %          lfpBattery.simpleSE lfpBattery.batteryInterface
    %          lfpBattery.nullIterator
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         January 2017
    properties (SetAccess = 'immutable', GetAccess = 'protected')
        s@lfpBattery.Stack; % Stack that holds the object's items.
        cObj@lfpBattery.batteryInterface; % Reference to the object that initially created the iterator
    end
    
    methods
        function i = batteryIterator(it, creatorObj)
            %BATTERYITERATOR: Creates an iterator.
            %
            %Syntax: i = BATTERYITERATOR(it, creatorObj);
            %
            %Input arguments:
            %it         - iterator object (must implement the iterator
            %               interface)
            %creatorObj - reference to the object that created the iterator
            lfpBattery.commons.validateInterface(it, 'lfpBattery.iterator')
            i.s = lfpBattery.Stack;
            i.s.push(it)
            i.cObj = creatorObj;
        end % constructor
        function obj = next(i)
            if i.hasNext
                it = i.s.peek; % retrieve the iterator on top of the Stack
                obj = it.next;
                if ~obj.isCell % add object's iterator to top of Stack if it is not a cell
                    i.s.push(obj.createIterator)
                    obj = i.next;
                end
            else
                obj = [];
            end
        end % next
        function tf = hasNext(i)
            if i.s.empty
                tf = false;
            else
                it = i.s.peek;
                if ~it.hasNext
                    i.s.pop; % remove top item from Stack
                    tf = i.hasNext; % Call function again through recursion
                else
                    tf = true;
                end
            end
        end % hasNext
        function reset(i)
            while ~i.s.empty
                i.s.pop;
            end
            i.s.push(i.cObj.createIterator);
        end
    end
    
end

