classdef commons
    %COMMONS: Class for commonly used static functions
    
    methods (Static)
        function onezeroChk(var, varName)
            % ONEZEROCHK: Returns an error if the variable var with varName
            % is not in the interval [0,..1]
            if var > 1 || var < 0
                error([varName, ' must be between 0 and 1'])
            end
        end
        function validateInterface(obj, name)
            % VALIDATEINTERFACE: Checks the superclasses to make sure the class obj subclasses
            % the superclass name
            if ~lfpBattery.commons.itfcmp(obj, name)
                error('Specified object does not implement the correct interface.')
            end
        end
        function tf = itfcmp(obj, name)
            % ITFCMP: Compares the class of obj to the name and returns
            % true if obj implements the interface specified by name.
            tf = any(ismember(superclasses(obj), name));
        end
        function y = upperlowerlim(y, low, high)
            % UPPERLOWERLIM: Limits y to interval [low, high]
            y = min(max(low, y), high);
        end
    end
    
end

