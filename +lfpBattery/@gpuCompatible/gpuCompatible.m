classdef (Abstract) gpuCompatible < handle
    %GPUCOMPATIBLE: Makes a class compatible with CUDA GPU computations.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         January 2017
    %
    %SEE ALSO: gpuArray
    
    methods
        function obj = gpuArray(obj)
            fn = obj.getAllFields;
            for i = 1:numel(fn)
                try % Some protected dependent props may not have getters or setters
                    val = obj.getsubProp(fn{i});
                    if isnumeric(val) || islogical(val) || lfpBattery.commons.itfcmp(val, 'lfpBattery.gpuCompatible')
                        try % may be dependent
                            obj.setsubProp(fn{i}, gpuArray(val));
                        catch
                        end
                    end
                catch
                end
            end
        end
        function obj = gather(obj)
            fn = obj.getAllFields;
            for i = 1:numel(fn)
                try % Some protected dependent props may not have getters or setters
                    val = obj.getsubProp(fn{i});
                    if isa(val, 'gpuArray')
                        obj.setsubProp(fn{i}, gather(val));
                    end
                catch
                end
            end
        end
    end
    methods (Access = 'protected')
        function fn = getAllFields(obj)
            warning('off', 'all')
            s = struct(obj);
            warning('on', 'all')
            fn = fieldnames(s); % all properties
        end
    end
    methods (Abstract, Access = 'protected')
        % Each object that implements this interface must include this
        % method. It must contain the following line:
        % obj.(fn) = val;
        setsubProp(obj, fn, val);
        % Each object that implements this interface must include this
        % method. It must contain the following line:
        % val = obj.(fn);
        val = getsubProp(obj, fn);
    end
end

