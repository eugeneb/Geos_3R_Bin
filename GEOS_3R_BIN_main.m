clear
clc

%fclose(instrfind)

fead_data_from='GEOS';
fead_data_from='file';

if(fead_data_from=='GEOS')
    %настройки COM порта
    Num_com_port='COM67';
    baud=115200;
    com_port=serial(Num_com_port, 'BaudRate', baud);
else
    name_bin_file='/geos_3MR_F_1_Hz.bin';
    com_port=fopen(name_bin_file);
end


%что обрабатывать
phData.NumPointPlot=30; % максимальное число точек на графике
phData.NumPointPoiskKA=5;    % число точек для поиска нужного КА
phData.chisl_spytnicov=96;%  число спутников 

%константы:
F0_gps=1.57542e9; % центральная частота gps
F0_gln=1.602e9; % центральная частота ГЛОНАСС
dF_gln=562500; %шаг по частоте ГЛОНАСС (ЧРК, литеры)
c=299792458; % скорость света

phData.reliable(1:phData.NumPointPlot,1:phData.chisl_spytnicov)=nan; 
phData.SignalToNoise(1:phData.NumPointPoiskKA,1:phData.chisl_spytnicov)=nan;
phData.phase(1:phData.NumPointPlot,1)=nan;
phData.time(1:phData.NumPointPlot,1)=nan;
phData.H_liter=nan;
phData.cycle_d(1:phData.NumPointPlot,1)=nan;
t_gps(1:phData.NumPointPlot,1)=nan;
% Bin.preamble=[hex2dec('47'); hex2dec('45'); hex2dec('4f'); hex2dec('53'); ...
%     hex2dec('72'); hex2dec('33'); hex2dec('50'); hex2dec('53')]; %преамбула GEOSr3PS

if(fead_data_from=='GEOS') %для прм GEOS-3R
    %настройки бинарного протокола приемника
    % выдача сообщений 0х10 и 0x13
    Bin.data_write(1:8,1)=[hex2dec('4F'); 0; 1; 0; 0; 0; 9; 0];
    GEOS_3R_BIN_DataWrite(Bin.data_write, com_port);
    
    % темп выдачи (1 Гц)
    Bin.data_write(1:8,1)=[hex2dec('44'); 0; 1; 0; 3; 0; 0; 0];
    GEOS_3R_BIN_DataWrite(Bin.data_write, com_port);
    
    fopen(com_port);
end

StartTime=-1; % время начала работы

while(1==1) % определяем номер КА
    for(cikl_for=1:phData.NumPointPoiskKA)
        %считывание даннных из порта
        
        [Bin.PH_data, phData.datN]=GEOS_3R_BIN_DataRead(16,com_port);

        
        while(1==1)% выбор спутника. критерий- макс. с/ш
            phData.NumKA=GEOS_3R_BIN_bin2num(Bin.PH_data(13:16,1),'int');
            fprintf('NUM KA: %d  \n', phData.NumKA) %print число КА в решение
            for(k=1:phData.NumKA)%обработка данных с "к"-го спутника
                [phData.tmp_KAnumber, phData.tmp_reliable, phData.tmp_SignalToNoise,...
                    phData.tmp_phase,phData.tmp_Doppler]=GEOS_3R_BIN_DataDecod_0x10(...
                    Bin.PH_data(4*(-9+14*k)-3:4*(4+14*k),1));
                phData.SignalToNoise(cikl_for,phData.tmp_KAnumber)=phData.tmp_SignalToNoise;
            end
            break
        end
        
    end
    %условия выхода из цикла выбора КА
   [logik,ind_KA]=max(sum(phData.SignalToNoise));%поиск максимального отношения с/ш
   if(logik>40*phData.NumPointPoiskKA) % для завершения поиска требуется отношение с/ш больше 40 dBHz
       fprintf('\n ok \n num KA= %d \n max signalTOnoise %f \n', ind_KA, logik/phData.NumPointPoiskKA)
       break
   else
       fprintf('\n not \n max signalTOnoise= %f \n', logik/phData.NumPointPoiskKA)
   end
end
fclose(com_port);
%закончили поиск
phData.SignalToNoise=nan;
phData.SignalToNoise(1:phData.NumPointPlot,1)=nan;

%phData.k=3.369036432266235e+003; %это можно удалять
%phData.o= 4.208831474092468e-004;
%1.603687500000000e+009;

if(fead_data_from=='GEOS')
    fopen(com_port);
else
    com_port=fopen(name_bin_file);
end

while(1==1) % обработка данных с заданного КА
%    fclose(com_port);
%    clc
%    fopen(com_port);
%    for(open_close_port=1:33)
        [Bin.PH_data,phData.datN]=GEOS_3R_BIN_DataRead(16,com_port);
        [Bin.navi_task,tmp]=GEOS_3R_BIN_DataRead(hex2dec('13'),com_port);
        
        while(1==1) %обработка сообщений 0х10 и 0х13
            fprintf('\n ____________0x10___________')
            
            for(m=1:phData.NumPointPlot-1)% смещаемся на такт вниз
                phData.phase(phData.NumPointPlot-m+1,1)=phData.phase(phData.NumPointPlot-m,1);
                phData.SignalToNoise(phData.NumPointPlot-m+1,1)=phData.SignalToNoise(phData.NumPointPlot-m,1);
                phData.reliable(phData.NumPointPlot-m+1,1)=phData.reliable(phData.NumPointPlot-m,1);
                phData.time(phData.NumPointPlot-m+1,1)=phData.time(phData.NumPointPlot-m,1);
                phData.cycle_d(phData.NumPointPlot-m+1,1)=phData.cycle_d(phData.NumPointPlot-m,1);
                t_gps(phData.NumPointPlot-m+1,1)=t_gps(phData.NumPointPlot-m,1);%0x13
            end
            
            [ phData.UTC, phData.cycle_d(1,1),  phData.kol_vo_KA, phData.SignalToNoise(1),...
                phData.phase(1),  phData.Doppler, phData.H_liter]=...
                GEOS_3R_BIN_KA_data_0x10( Bin.PH_data,  ind_KA);
            if(StartTime<0) %задаём начальное время (для графиков)
                StartTime=phData.UTC;
                %phData.b=phData.phase(1,1)+phData.k*phData.o*(16369003-phData.cycle_d(1,1));%удалить
                %частота сигнала:
                if(ind_KA<65)
                    F_signal=F0_gps;
                else
                    F_signal=F0_gln+phData.H_liter*dF_gln;
                end
%            else
%                phData.phase(1,1)=phData.phase(1,1)+...
%                    abs(phData.cycle_d(1,1)-phData.cycle_d(2,1))*...
%                    0.5*F_signal*(16369002.5-phData.cycle_d(1,1)-phData.cycle_d(2,1))/16369002.5;%-
%             phData.phase(1,1)=phData.phase(1,1)-F_signal/16369000*(phData.cycle_d(1,1)-16369002)*...
%                 (phData.phase(1,1)-phData.phase(2,1))/abs(phData.phase(1,1)-phData.phase(2,1));
            end
           phData.time(1,1)=(phData.UTC-StartTime); %по НС определяем
            %phData.time(1,1)=phData.time(1,1)+1+(phData.cycle_d(1,1)-16369000)/16369000;
            %phData.time(1,1)=(phData.UTC-StartTime)+1000000*(16369002.5-phData.cycle_d(1,1))/16369000;
           % phData.time(1,1)=phData.time(1,1)+1-(16369002.5-phData.cycle_d(1,1))/16369002.5;
           %phData.phase(1,1)=phData.phase(1,1)+0.5*F_signal*(16369002.5-phData.cycle_d(1,1))/16369002.5;
           %phData.time(1,1)=(phData.phase(1,1)-phData.b)/phData.k;
           fprintf('\n UTC (01.01.2008): %9.0f sec', phData.UTC);
            fprintf('\n number KA: %d', phData.kol_vo_KA);
            t_gps(1,1)=GEOS_3R_BIN_navi_task_0x13(Bin.navi_task);%0x13
            break;
        end

        %обработка данных:
        if(sum(~isnan(phData.phase))>2)
            k=find(isnan(phData.phase)==0);
            apr.phase=phData.phase(k);
            apr.time=phData.time(k);
            apr.p2=polyfit(apr.time,apr.phase,2);
            apr.DataFit = polyval(apr.p2,apr.time);
            apr.DataPhase2=(apr.phase-apr.DataFit);
            tmp=0;
            m=0;
            for(k=1:length(apr.DataPhase2))
                if(isnan(apr.DataPhase2)==0)
                    tmp=tmp+apr.DataPhase2(k);
                    m=m+1;
                end
            end
            apr.sredn(1:length(apr.DataPhase2))=tmp/m;
        else
            apr.DataPhase2=nan;
            apr.DataFit=nan;
            apr.time=nan;
            apr.aprTime=nan;
            apr.aprDataPhase2=nan;
            apr.sredn=nan;
        end       
        
        %вывод графиков:
        subplot(2,2,1)
        plot(phData.time, phData.cycle_d,'r')
        xlabel('time, sec');
        ylabel('phase, cycles');
        subplot(2,2,2)
        plot(phData.time,phData.SignalToNoise)
        xlabel('time, sec');
        ylabel('signal to noise, dBHz');
        subplot(2,2,3)
        plot(apr.time,apr.DataPhase2,'b')
        xlabel('time, sec');
        ylabel('d phase, cycles');
        subplot(2,2,4)
        plot(phData.time,phData.phase, 'b',apr.time, apr.DataFit,'r')
        xlabel('time, sec');
        ylabel('d phase, ');
        drawnow
%    end
end
    
        
        
        
       
    


