classdef const
    %CONST: class for holding physical constants and shared variables
    properties (Constant)
        F = 96485.3328959; % As/mol - Faraday constant
        R = 8.3144598; % J/(mol*K) - universal gas constant
        T_room = 293.15; % K - room temperature
        z_Li = 1.05; % Charge number Li-Ion battery
        
        %% TU Colors
        red = [163 48 40]./255; %red
        green = [70 120 104]./255; %green
        blue = [71 115 150]./255; %blue
        black = [0 0 0]./255; %black
        yellow = [215 155 40]./255; %yellow
        grey = [113 113 113]./255; %grey
        logo = [197 14 31]./255; %logo red
        % CorpDesign
        corpDesign = [163 48 40; ...
            70 120 104; ...
            71 115 150; ...
            0 0 0; ...
            215 155 40; ...
            113 113 113; ...
            197 14 31] ./ 255;
        cmap = [0.6451    0.1952    0.1556 % colormap
            0.7545    0.3341    0.1346
            0.8266    0.4460    0.1258
            0.8612    0.5309    0.1291
            0.8585    0.5889    0.1446
            0.8184    0.6200    0.1722
            0.7409    0.6241    0.2119
            0.6260    0.6013    0.2638
            0.4737    0.5515    0.3279
            0.2840    0.4747    0.4041];

    end
end

