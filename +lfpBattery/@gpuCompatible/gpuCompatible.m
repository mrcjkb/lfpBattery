classdef (Abstract) gpuCompatible < handle
    % This class is currently undocumented and may be removed in a future
    % version of the package.
    
    %GPUCOMPATIBLE: Makes a class compatible with CUDA GPU computations.
    %
    %
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         January 2017
    %
    %SEE ALSO: gpuArray
    properties (Access = 'protected')
        isgpuObject@logical scalar = false;
    end
    methods
        function obj = gpuArray(obj)
            fn = obj.getAllFields;
            for i = 1:numel(fn)
                try % Some protected dependent props may not have getters or setters
                    val = obj.getsubProp(fn{i});
                    if isnumeric(val) || islogical(val)
                        obj.setsubProp(fn{i}, gpuArray(val));
                    elseif lfpBattery.commons.itfcmp(val, 'lfpBattery.gpuCompatible')
                        if ~val(1).isgpuObject
                            val(1).isgpuObject = true;
                            gpuval = []; % Object arrays should be converted one by one
                            for j = 1:numel(val)
                                gpuval = [gpuval; gpuArray(val(j))]; %#ok<AGROW>
                            end
                            obj.setsubProp(fn{i}, gpuval);
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
                    gpuval = obj.getsubProp(fn{i});
                    if isa(val, 'gpuArray')
                        obj.setsubProp(fn{i}, gather(gpuval));
                    elseif lfpBattery.commons.itfcmp(gpuval, 'lfpBattery.gpuCompatible')
                        if gpuval(1).isgpuObject
                            gpuval(1).isgpuObject = false;
                            val = [];
                            for j = 1:numel(gpuval)
                                val = [val; gather(gpuval(j))]; %#ok<AGROW>
                            end
                            obj.setsubProp(fn{i}, val)
                        end
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
        % GETSUBPROP:
        % Each object that implements this interface must include this
        % method. 
        % It must contain the following line:
        % 
        % obj.(fn) = val;
        % 
        % Note: Every subclass that has protected properties must include this method in order for the
        % conversion to work properly.
        setsubProp(obj, fn, val);
        % GETSUBPROP:
        % Each object that implements this interface must include this
        % method.
        % It must contain the following line:
        % 
        % val = obj.(fn);
        % 
        % Note: Every subclass that has protected properties must include this method in order for the
        % conversion to work properly.
        val = getsubProp(obj, fn);
    end
end

