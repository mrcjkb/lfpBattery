classdef digitizeToolOTHER < lfpBattery.digitizeToolState
    %DIGITIZETOOLOTHER digitizeTool State object for curve digitizing
    %without curve fitting
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         February 2017
    %
    %SEE ALSO: lfpBattery.digitizeTool lfpBattery.digitizeToolState
    %lfpBattery.digitizeToolCL lfpBattery.digitizeToolCCCV lfpBattery.digitizeToolDC
    
    properties
        xLabel = 'X data';
        yLabel = 'Y data';
    end
    properties (Dependent, SetAccess = 'protected')
        numsets;
        I;
        T;
    end
    
    methods
        function obj = digitizeToolOTHER(varargin)
            obj@lfpBattery.digitizeToolState(varargin{:})
        end
        function chk = getYAxisYdata(obj)
            chk = getYAxisYdata@lfpBattery.digitizeToolState(obj);
            % Determine Y-axis scaling
            Ytype = questdlg(['Axis scaling (', obj.yLabel,')'], ...
                'Walkthrough', ...
                'LINEAR', 'LOGARITHMIC', 'CANCEL', 'LINEAR');
            drawnow
            switch Ytype
                case 'LINEAR'
                    obj.scalefactorYdata = obj.YAxisYdata - obj.OriginXYdata(2);
                case 'LOGARITHMIC'
                    obj.logy = true;
                    obj.scalefactorYdata = log10(obj.YAxisYdata / obj.OriginXYdata(2));
                case 'CANCEL'
                    obj.dTool.errCt = 7;
                    error('cancelled')
            end
        end % getYAxisYdata
        function chk = getXAxisXdata(obj)
            chk = getXAxisXdata@lfpBattery.digitizeToolState(obj);
            % Determine Y-axis scaling
            Ytype = questdlg(['Axis scaling (', obj.yLabel,')'], ...
                'Walkthrough', ...
                'LINEAR', 'LOGARITHMIC', 'CANCEL', 'LINEAR');
            drawnow
            switch Ytype
                case 'LINEAR'
                    obj.scalefactorXdata = obj.XAxisXdata - obj.OriginXYdata(1);
                case 'LOGARITHMIC'
                    obj.logx = true;
                    obj.scalefactorXdata = log10(obj.XAxisXdata / obj.OriginXYdata(1));
                case 'CANCEL'
                    obj.dTool.errCt = 7;
                    error('cancelled')
            end
        end % getXAxisXdata
        function n = get.numsets(obj)
            dlgTitle = 'User input';
            def = {'5'};
            prompt = 'Please type in the number of curves to digitize.';
            obj.dTool.hInfo.setText(['<html>INFO<br><br>', prompt, '</html>");'])
            chk = true;
            while chk
                answer = inputdlg(prompt, dlgTitle, 1, def);
                n = round(str2double(char(answer{:})));
                if n <= 0
                    waitfor(msgbox('Please insert a number greater than 0.','ERROR','error'))
                else
                    chk = false;
                end
            end
        end % get numsets
        function i = get.I(obj) %#ok<MANU>
            i = [];
        end
        function t = get.T(obj) %#ok<MANU>
            t = [];
        end
        function f = createFit(~, ~)
            % nothing to be done here
            f = [];
        end
        function plotResults(obj)
            obj.dTool.fit.plotResults
        end % plotResults
    end
    
end

