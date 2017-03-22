classdef digitizeToolCCCV < lfpBattery.digitizeToolState
    %DIGITIZETOOLCCCV digitizeTool State object for CCCV (constant current
    %constant voltage charge curve digitizing and fitting.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         February 2017
    %
    %SEE ALSO: lfpBattery.digitizeTool lfpBattery.digitizeToolState lfpBattery.digitizeToolDC
    %lfpBattery.digitizeToolCL 
    properties
        xLabel = 'state of charge';
        yLabel = 'maximum current in A';
    end
    properties (Access = 'protected')
        aqmarker2;
        x_p0;
        i0;
        soc0;
    end
    properties (Dependent, SetAccess = 'protected')
        numsets;
        I;
        T;
    end
    methods
        function obj = digitizeToolCCCV(varargin)
            obj@lfpBattery.digitizeToolState(varargin{:})
            obj.Origprompt = {['Ordinate (', obj.xLabel ,') at origin:'] ,...
                ['Ordinate (', obj.yLabel, ') at origin:'],...
                'Repeat selection? (Y/N)'};
            obj.Xmsg = ['Select a coordinate on the ordinate (', obj.xLabel, ') with the left mouse button.'];
            obj.xDataLock = 'x';
        end % Constructor
        function chk = getXAxisXdata(obj)
            chk = getXAxisXdata@lfpBattery.digitizeToolState(obj);
            obj.scalefactorXdata = obj.XAxisXdata - obj.OriginXYdata(2); % x data is on abscissa
            % No rotation necessary, since x axis is disregarded
            obj.rotmat = [1 0; 0 1];
        end
        function [X, Y, acquiring, n, addData] = getXYpoint(obj, n, cct)
            import lfpBattery.*
            X = []; Y = [];
            if n == 0
                obj.msgStr{1} = ['Select a data point on CURRENT curve with the LEFT mouse button.', ...
                    '<br><br> Start at the beginning of the constant voltage phase.'];
            else
                obj.msgStr{1} = 'Select a data point on CURRENT curve with the LEFT mouse button.';
            end
            obj.msgStr{2} = 'Correction with the MIDDLE mouse button.';
            obj.msgStr{3} = 'RIGHT click when done.';
            obj.dTool.aquiringInfoUpdate(obj.msgStr)
            chk = true;
            while chk
                if n > 0
                    hL = addlistener(obj.dTool.mainframe, ...
                        'WindowMouseMotion', @(x, y) digitizeToolCCCV.limitPointer(obj.x_p0, obj.i0{n}));
                end
                [x,y, buttonNumber] = ginput(1);
                x_p2 = get(0, 'PointerLocation');
                if n > 0
                    delete(hL)
                else
                    obj.x_p0 = x_p2;
                end
                if buttonNumber == 1
                    n = n + 1;
                    obj.aqmarker(n) = line(x, y, 'Marker','.','Color', obj.colors(cct, :), 'MarkerSize', 12);
                    xy = obj.rotmat * [(x - obj.Xopixels); (y - obj.Yopixels)];
                    delYpoint = xy(2) ./ obj.delYcal .* obj.scalefactorYdata;
                    Y = obj.OriginXYdata(2) + delYpoint;
                    chk = false;
                else
                    [acquiring, n, addData] = obj.handleButtonNumber(buttonNumber, n);
                    if acquiring
                        try delete(obj.aqmarker(n)); catch; end
                    end
                    return
                end
            end
            obj.msgStr{1} = 'Select the respective data point on the SOC curve with the LEFT mouse button.';
            obj.msgStr{2} = 'Correction with the MIDDLE mouse button.';
            obj.msgStr{3} = ['Note: Only the point at the beginning of the CV phase is needed for fitting.', ...
                ' However, more points can be selected for the purpose of validating the linear fit results.'];
            obj.dTool.aquiringInfoUpdate(obj.msgStr)
            chk = true;
            while chk
                if n > 0
                    if n == 1
                        obj.soc0{n} = [0 0];
                    end
                    hL = addlistener(obj.dTool.mainframe, ...
                        'WindowMouseMotion', @(x, y) digitizeToolCCCV.lockPointer(x_p2, obj.soc0{n}));
                end
                [x,y, buttonNumber] = ginput(1);
                x_p3 = get(0, 'PointerLocation');
                if n > 0
                    delete(hL)
                end
                if buttonNumber == 1
                    obj.aqmarker2(n) = line(x, y, 'Marker','.','Color', obj.colors(cct + 1, :), 'MarkerSize', 12);
                    xy = obj.rotmat * [(x - obj.Xopixels); (y - obj.Yopixels)];
                    % Convert pixel Y data to X data for fit
                    delXpoint = xy(2) ./ obj.delXcal .* obj.scalefactorXdata;
                    X = obj.OriginXYdata(2) + delXpoint;
                    acquiring = true;
                    addData = true;
                    obj.i0{n} = x_p2;
                    obj.soc0{n+1} = x_p3;
                    chk = false;
                elseif buttonNumber == 2
                    n0 = n;
                    [acquiring, n, addData] = obj.handleButtonNumber(buttonNumber, n);
                    try delete(obj.aqmarker2(n0)); catch; end
                    if n < n0
                        return
                    end
                end
            end
        end % getXYpoint
        function rotmatDef(obj)
            delxyx = rotmatDef@lfpBattery.digitizeToolState(obj);
            obj.delXcal = delxyx(2); % Extract data in y direction
        end
        function deleteMarkers(obj, n)
            try delete(obj.aqmarker(n)); catch; end
            try delete(obj.aqmarker2(n)); catch; end
        end
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
            f = cccvFit(obj.dTool.ImgData(1).x, obj.dTool.ImgData(1).y);
        end
    end
    methods (Static)
        function lockPointer(xp, soc0)
            x = get(0, 'PointerLocation');
            x(1) = xp(1);
            x(2) = max(x(2), soc0(2));
            set(0, 'PointerLocation', x);
        end
        function limitPointer(xp0, i0)
            x = get(0, 'PointerLocation');
            x(1) = max(xp0(1), x(1));
            x(2) = min(i0(2), x(2));
            set(0, 'PointerLocation', x);
        end
    end
end

