classdef digitizeToolCL < lfpBattery.digitizeToolState
    %DIGITIZETOOLCL digitizeTool State object for cycle life curve
    %digitizing and fitting.
    
    properties
        xLabel = 'depth of discharge';
        yLabel = 'cycles to failure';
    end
    properties (Dependent, SetAccess = 'protected')
        numsets;
        I;
        T;
    end
    
    methods
        function obj = digitizeToolCL(varargin)
            obj@lfpBattery.digitizeToolState(varargin{:})
        end
        function [scalefactorYdata, chk] = getYAxisYdata(obj)
            [~, chk] = getYAxisYdata@lfpBattery.digitizeToolState(obj);
            % Determine Y-axis scaling
            Ytype = questdlg('Axis scaling (Y)', ...
                'Walkthrough', ...
                'LINEAR', 'LOGARITHMIC', 'CANCEL', 'LINEAR');
            drawnow
            switch Ytype
                case 'LINEAR'
                    scalefactorYdata = YAxisYdata - OriginXYdata(2);
                case 'LOGARITHMIC'
                    obj.logy = true;
                    scalefactorYdata = log10(YAxisYdata/OriginXYdata(2));
                case 'CANCEL'
                    obj.dTool.errCt = 7;
                    error('cancelled')
            end
        end % getYAxisYdata
        function n = get.numsets(obj) %#ok<MANU>
            n = 1;
        end
        function i = get.I(obj) %#ok<MANU>
            i = [];
        end
        function t = get.T(obj) %#ok<MANU>
            t = [];
        end
        function f = createFit(obj, ~)
            import lfpBattery.*
            f = woehlerFit(obj.dTool.ImgData(1).x, obj.dTool.ImgData(1).y); %(N, DoD)
        end
        function plotResults(obj)
            obj.dTool.fit.plotResults(true)
        end
    end
    
end

