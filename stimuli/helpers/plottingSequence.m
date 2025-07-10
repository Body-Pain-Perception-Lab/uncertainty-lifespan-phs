%% TGI-fMRI plotting
% plot the sequence for presentations

% Created by A.G. Mitchell on 22.03.2024
% NB: relevant data from example participant will need loading

%% Arrange data
% concatenate tcs data
tcsData = cat(1,results.tcsData{1,:});

% split into individual trials, first 5
trial1 = tcsData(tcsData(:,1) == 1, :);
trial2 = tcsData(tcsData(:,1) == 2, :);
trial3 = tcsData(tcsData(:,1) == 3, :);
trial4 = tcsData(tcsData(:,1) == 4, :);
trial5 = tcsData(tcsData(:,1) == 5, :);

%% Colours
innocCold = [0.3010 0.7450 0.9330];
innocWarm = [0.9290 0.6940 0.1250];
noxCold = [0 0.4470 0.7410];
noxHot = [0.6350 0.0780 0.1840];
TGI = [0.4940 0.1840 0.5560];
  
%% Plotting sequence
figure(1)
plot(trial1(:,8), trial1(:, 3:7), 'Color', innocCold, 'LineWidth', 1.2)
hold on
plot(trial2(:,8), trial2(:, 3:7), 'Color', noxCold, 'LineWidth', 1.2)
plot(trial3(:,8), trial3(:, 3:7), 'Color', TGI, 'LineWidth', 1.2)
plot(trial4(:,8), trial4(:, 3:7), 'Color', innocWarm, 'LineWidth', 1.2)
plot(trial5(:,8), trial5(:, 3:7), 'Color', noxHot, 'LineWidth', 1.2)
%plot(tcsData(:,2), (rampOff_code*max(tcsData(end, 3:7))), '.', 'markersize', 4)
xlabel('Time since trigger (s)')
ylabel('Temperature (°C)')
%legend('z1','z2','z3','z4','z5')
ylim([0 50])
zoom on; grid off; box off;
hold off
fig = gcf;

exportgraphics(gcf,'example_sequence.png','Resolution',600)
