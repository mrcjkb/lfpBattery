classdef digitizeToolDC < lfpBattery.digitizeToolState
    %DIGITIZETOOLDC digitizeTool State object for discharge curve
    %digitizing and fitting.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         February 2017
    %
    %SEE ALSO: lfpBattery.digitizeTool lfpBattery.digitizeToolState
    %lfpBattery.digitizeToolCL lfpBattery.digitizeToolCCCV
    
    properties
        xLabel = 'discharge capacity in Ah';
        yLabel = 'voltage in V';
    end
    properties (Dependent, SetAccess = 'protected')
        numsets;
        I;
        T;
    end
    
    methods
        function obj = digitizeToolDC(varargin)
            obj@lfpBattery.digitizeToolState(varargin{:})
        end
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
        function i = get.I(obj)
            dlgTitle = 'User input';
            def = {'1'};
            prompt = 'Please type in the current in A.';
            obj.dTool.hInfo.setText(['<html>INFO<br><br>', prompt, '</html>");'])
            chk = true;
            while chk
                answer = inputdlg(prompt, dlgTitle, 1, def);
                i = round(str2double(char(answer{:})));
                if i <= 0
                    waitfor(msgbox('Please insert a number greater than 0.','ERROR','error'))
                else
                    chk = false;
                end
            end
        end % get I
        function t = get.T(obj)
            dlgTitle = 'User input';
            def = {'20'};
            prompt = 'Please type in the temperature in °C.';
            obj.dTool.hInfo.setText(['<html>INFO<br><br>', prompt, '</html>");'])
            chk = true;
            while chk
                answer = inputdlg(prompt, dlgTitle, 1, def);
                t = round(str2double(char(answer{:}))) + 273.15;
                if t < 0
                    waitfor(msgbox('Please insert a number greater than -273.15.','ERROR','error'))
                else
                    chk = false;
                end
            end
        end % get T
        function f = createFit(obj, numsets)
            import lfpBattery.*
            f = dischargeCurves;
            for si = 1:numsets
                df = dischargeFit(obj.dTool.ImgData(si).y, obj.dTool.ImgData(si).x, ...
                    obj.dTool.ImgData(si).I, obj.dTool.ImgData(si).T);
                f.add(df);
            end
        end
        function plotResults(obj)
            obj.dTool.fit.plotResults
        end % plotResults
    end
end

