classdef (Abstract) digitizeToolState < handle
    %DIGITIZETOOLSTATE: Abstract class for implementing the State design
    %pattern in the digitizeTool class. Any state that is added to the tool
    %must implement this interface.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         February 2017
    %
    %SEE ALSO: lfpBattery.digitizeTool lfpBattery.digitizeToolDC
    %lfpBattery.digitizeToolCL lfpBattery.digitizeToolCCCV
    properties (Abstract)
        xLabel;
        yLabel;
    end
    properties (Abstract, Dependent, SetAccess = 'protected')
        numsets;
        I;
        T;
    end
    properties
        Xopixels;
        Yopixels;
        XAxisXpixels;
        XAxisYpixels;
        YAxisXpixels;
        YAxisYpixels;
        colors = lfpBattery.const.corpDesign;
        msgStr = cell(3, 1);
    end
    properties (Access = 'protected')
        dTool; % reference to digitizeTool object
        Origprompt;
        Xmsg;
        Ymsg;
        xDataLock;
        yDataLock;
        OriginXYdata;
        XAxisXdata;
        YAxisYdata;
        x_p;
        logx = false;
        logy = false;
        scalefactorXdata;
        scalefactorYdata;
        rotmat;
        delXcal;
        delYcal;
        aqmarker;
    end
    
    methods
        function obj = digitizeToolState(dT)
            obj.dTool = dT;
            obj.Origprompt={['Abscissa (', obj.xLabel ,') at origin:'] ,...
                ['Ordinate (', obj.yLabel, ') at origin:'],...
                'Repeat selection? (Y/N)'};
            obj.Xmsg = ['Select a coordinate on the abscissa (', obj.xLabel, ') with the left mouse button.'];
            obj.Ymsg = ['Select a coordinate on the ordinate (', obj.yLabel, ') with the left mouse button.'];
            obj.xDataLock = 'y';
            obj.yDataLock = 'x';
            obj.msgStr{1} = 'Select data points with the LEFT mouse button.';
            obj.msgStr{2} = 'Correction with the MIDDLE mouse button.';
            obj.msgStr{3} = 'RIGHT click when done.';
        end % Constructor
        function chk = getOrigin(obj)
            import lfpBattery.*
            % Determine location of origin with mouse click
            msg = 'Select the ORIGIN with the left mouse button.';
            obj.dTool.hInfo.setText(['<html>INFO<br><br>', msg, '</html>");'])
                    drawnow
                    [obj.Xopixels, obj.Yopixels, buttonNumber] = ginput(1);
                    obj.x_p = get(0, 'PointerLocation');
                    inp = line(obj.Xopixels, obj.Yopixels,...
                        'Marker', 'o', 'Color', const.green, 'MarkerSize', 14);
                    inp2 = line(obj.Xopixels, obj.Yopixels,...
                        'Marker', 'x', 'Color', const.green, 'MarkerSize', 14);
                    if buttonNumber ~= 1
                        delete(inp)
                        delete(inp2)
                        chk = obj.cancelRequest;
                        return
                    end
            def = {'0', '0', 'N'};
            dlgTitle = 'User input';
            obj.dTool.hInfo.setText(['<html>INFO<br><br>', obj.Origprompt{1}, '<br>', obj.Origprompt{2} '</html>");'])
            answer = inputdlg(obj.Origprompt, dlgTitle, 1, def);
            if (isempty(char(answer{:})) == 1)
                obj.dTool.errCt = 7;
                error('cancelled')
            elseif strcmp(char(answer{3}), 'Y')
                delete(inp)
                delete(inp2)
                error('chk')
            else
                answer = answer(1:2);
                obj.OriginXYdata = [str2double(char(answer{1}));...
                    str2double(char(answer{2}))];
                chk = false;
            end
        end % getOrigin
        function chk = getXAxisXdata(obj)
            import lfpBattery.*
            obj.dTool.hInfo.setText(['<html>INFO<br><br>', obj.Xmsg, '</html>");'])
            drawnow
            hL = addlistener(obj.dTool.mainframe, 'WindowMouseMotion', @(x, y) digitizeTool.lockPointer(obj.x_p, obj.xDataLock));
            [obj.XAxisXpixels, obj.XAxisYpixels, buttonNumber] = ginput(1);
            delete(hL)
            inp = line(obj.XAxisXpixels, obj.XAxisYpixels,...
                'Marker', '*', 'Color', const.green, 'MarkerSize', 14);
            inp2 = line(obj.XAxisXpixels, obj.XAxisYpixels,...
                'Marker', 's', 'Color', const.green, 'MarkerSize', 14);
            if buttonNumber ~= 1
                delete(inp)
                delete(inp2)
                chk = obj.cancelRequest;
                return
            end
            % Prompt user for XLim value
            msg = [obj.xLabel, ' at the selected coordinate:'];
            obj.dTool.hInfo.setText(['<html>INFO<br><br>', msg, '</html>");'])
            prompt = {msg; 'Repeat? (Y/N)'};
            def = {'1', 'N'};
            dlgTitle = 'User input';
            answer = inputdlg(prompt, dlgTitle, 1, def);
            if (isempty(char(answer{:})) == 1)
                obj.dTool.errCt = 7;
                error('cancelled')
            elseif strcmp(answer{2},'Y')
                delete(inp)
                delete(inp2)
                error('chk')
            else
                answer = answer(1);
                obj.XAxisXdata = str2double(char(answer{:}));
                chk = false;
            end
            obj.scalefactorXdata = obj.XAxisXdata - obj.OriginXYdata(1);
            % Rotate image if necessary
            % note image file line 1 is at top
            th = atan((obj.XAxisYpixels - obj.Yopixels) / (obj.XAxisXpixels - obj.Xopixels));
            % axis rotation matrix
            obj.rotmat = [cos(th) sin(th); -sin(th) cos(th)];
        end % getXAxisXdata
        function chk = getYAxisYdata(obj)
            import lfpBattery.*
            obj.dTool.hInfo.setText(['<html>INFO<br><br>', obj.Ymsg, '</html>");'])
            drawnow
            hL = addlistener(obj.dTool.mainframe, 'WindowMouseMotion', @(x, y) lfpBattery.digitizeTool.lockPointer(obj.x_p, obj.yDataLock));
            [obj.YAxisXpixels, obj.YAxisYpixels, buttonNumber] = ginput(1);
            delete(hL)
            inp = line(obj.YAxisXpixels, obj.YAxisYpixels,...
                'Marker', '*', 'Color', const.green, 'MarkerSize', 14);
            inp2 = line(obj.YAxisXpixels, obj.YAxisYpixels,...
                'Marker', 's', 'Color', const.green, 'MarkerSize', 14);
            if buttonNumber ~= 1
                delete(inp)
                delete(inp2)
                chk = obj.cancelRequest;
                return
            end
            % Prompt user for YLim value
            msg = [obj.yLabel, ' at the selected coordinate:'];
            obj.dTool.hInfo.setText(['<html>INFO<br><br>', msg, '</html>");'])
            prompt = {msg, 'Repeat? (Y/N)'};
            def = {'1', 'N'};
            dlgTitle = 'User input';
            answer=inputdlg(prompt, dlgTitle, 1, def);
            if (isempty(char(answer{:})) == 1)
                obj.dTool.errCt = 7;
                error('cancelled')
            elseif strcmp(answer{2},'Y')
                delete(inp)
                delete(inp2)
                error('chk')
            else
                answer = answer(1);
                obj.YAxisYdata = str2double(char(answer{:}));
                chk = false;
            end
            obj.scalefactorYdata = obj.YAxisYdata - obj.OriginXYdata(2);
        end % getYAxisYdata
        function [delXYX, delXYY] = rotmatDef(obj)
            delxyx = obj.rotmat * [(obj.XAxisXpixels - obj.Xopixels); ...
                (obj.XAxisYpixels - obj.Yopixels)];
            delxyy = obj.rotmat * [(obj.YAxisXpixels - obj.Xopixels); ...
                (obj.YAxisYpixels - obj.Yopixels)];
            obj.delXcal = delxyx(1);
            obj.delYcal = delxyy(2);
            if nargout > 0
                delXYX = delxyx;
            end
            if nargout > 1
                delXYY = delxyy;
            end
        end
        function [x, y, acquiring, n, addData] = getXYpoint(obj, n, cct)
            [x,y, buttonNumber] = ginput(1);
            if buttonNumber == 1
                n = n + 1;
                obj.aqmarker(n) = line(x, y, 'Marker','.','Color', obj.colors(cct, :), 'MarkerSize', 12);
                xy = obj.rotmat * [(x - obj.Xopixels); (y - obj.Yopixels)];
                delXpoint = xy(1) ./ obj.delXcal .* obj.scalefactorXdata;
                delYpoint = xy(2) ./ obj.delYcal .* obj.scalefactorYdata;
                obj.msgStr{2} = 'Correction with the MIDDLE mouse button.';
                obj.dTool.aquiringInfoUpdate(obj.msgStr)
                if obj.logx
                    x = obj.OriginXYdata(1) .* 10 .^ delXpoint;
                else
                    x = obj.OriginXYdata(1) + delXpoint;
                end
                if obj.logy
                    y = obj.OriginXYdata(2) .* 10 .^ delYpoint;
                else
                    y = obj.OriginXYdata(2) + delYpoint;
                end
                acquiring = true;
                addData = true;
            else
                [acquiring, n, addData] = obj.handleButtonNumber(buttonNumber, n);
            end
        end % getXYpoint
        function [acquiring, n, addData] = handleButtonNumber(obj, buttonNumber, n)
            addData = false;
            acquiring = true;
            if buttonNumber == 3 && n == 0
                query = questdlg('No data selected. Cancel?', ...
                    'CANCEL?', ...
                    'YES', 'NO', 'NO');
                drawnow
                if strcmp(query,'YES')
                    error('cancelled')
                end
            elseif buttonNumber == 3
                query = questdlg('Done?', ...
                    'CONFIRM', ...
                    'YES', 'NO', 'NO');
                drawnow
                if strcmp(query,'YES')
                    acquiring = false;
                end
            elseif buttonNumber == 2 && n > 0
                query = questdlg('Correct last point?', ...
                    'CORRECTION?', ...
                    'CORRECTION', 'CONTINUE', 'CONTINUE');
                drawnow
                if strcmp(query,'CORRECTION')
                    obj.deleteMarkers(n)
                    n = n - 1;
                    obj.msgStr{2} = 'Correction...';
                    obj.dTool.aquiringInfoUpdate(obj.msgStr)
                end
            end
        end % handleButtonNumber
        function deleteMarkers(obj, n)
            delete(obj.aqmarker(n))
        end
        function chk = cancelRequest(obj)
            prompt = questdlg('Cancel?', 'Walkthrough', 'YES', 'NO', 'NO');
            if strcmp(prompt, 'YES')
                obj.dTool.errCt = 7;
                error('cancelled')
            end
            chk = true;
        end % cancelRequest
        function plotResults(obj)
            obj.dTool.fit.plotResults(true)
        end % plotResults
    end
    methods (Abstract)
        f = createFit(obj, numsets);
    end
end
