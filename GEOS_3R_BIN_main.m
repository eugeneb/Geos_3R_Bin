clear
clc

%fclose(instrfind)

%fead_data_from='GEOS';
fead_data_from='file';

if (fead_data_from=='GEOS')      % Настройки из порта
    Num_com_port = 'COM67';   
    baud = 115200;
    stream = serial(Num_com_port, 'BaudRate', baud);
else                             % Работа из файла
    name_bin_file = 'bin_data_file/geos_3MR_F_1_Hz.bin';
    stream = fopen(name_bin_file, 'r');
end


% Что обрабатывать
phData.NumPointPlot=30;          % Максимальное число точек на графике
phData.NumPointPoiskKA=5;        % Число точек для поиска нужного КА
phData.chisl_spytnicov=96;       % Число спутников 

% Константы:
F0_gps=1.57542e9;                % Центральная частота gps
F0_gln=1.602e9;                  % Центральная частота ГЛОНАСС
dF_gln=562500;                   % Шаг по частоте ГЛОНАСС (ЧРК, литеры)
c=299792458;                     % Скорость света

% Выделение памяти под массивы для данных
phData.reliable(1:phData.NumPointPlot,1:phData.chisl_spytnicov) = nan; 
phData.SignalToNoise(1:phData.NumPointPoiskKA,1:phData.chisl_spytnicov) = nan;
phData.phase(1:phData.NumPointPlot,1) = nan;
phData.time(1:phData.NumPointPlot,1) = nan;
phData.H_liter = nan;
phData.cycle_d(1:phData.NumPointPlot,1) = nan;
t_gps(1:phData.NumPointPlot,1) = nan;

if(fead_data_from=='GEOS')       % Для прм GEOS-3R
                                 % Настройки бинарного протокола приемника
                                 % Выдача сообщений 0х10 и 0x13

    % Отправка пакета 0x4F - разрешение бинарных сообщений
    Bin.data_write(1:8,1)=[hex2dec('4F'); 0; 1; 0; 0; 0; 9; 0];
    GEOS_3R_BIN_DataWrite(Bin.data_write, stream);
    
    % Отправка пакета 0x44 - темп выдачи (1 Гц)
    Bin.data_write(1:8,1)=[hex2dec('44'); 0; 1; 0; 3; 0; 0; 0];
    GEOS_3R_BIN_DataWrite(Bin.data_write, stream);
    
    fopen(stream);
end

StartTime=-1; % время начала работы

while (1)    % Выбираем КА, с которым дальше будем работать
    for ch=1:phData.NumPointPoiskKA
        % Считывание пакета 16 (0x10) - измерительная информация каналов 
        
        [Bin.PH_data, phData.datN] = GEOS_3R_BIN_DataRead(16, stream);
        
        % Преобразование слова "Количество КА"
        phData.NumKA=GEOS_3R_BIN_bin2num(Bin.PH_data(13:16,1), 'int');
        fprintf('NUM KA: %d  \n', phData.NumKA)
        
        for k=1:phData.NumKA      % Обработка всех спутников из пакета 0x10

            % Номера байт, отвещающих за спутник k в пакете 0x10
            rec_ind = 4*(-9+14*k)-3:4*(4+14*k);

            % Выделение измерений одно КА из пакета 0x10
            [phData.tmp_KAnumber        ...   % Номер НС
             phData.tmp_reliable        ...   % Флаги достоверности
             phData.tmp_SignalToNoise   ...   % q, дБГц
             phData.tmp_phase           ...   % Фаза
             phData.tmp_Doppler     ] = ...   % Смещение частоты
                GEOS_3R_BIN_DataDecod_0x10( Bin.PH_data(rec_ind, 1) );
            
            % Заполнение массива отношением сигнал/шум
            phData.SignalToNoise(ch, phData.tmp_KAnumber) = phData.tmp_SignalToNoise;
        end
        
    end
    
    % условия выхода из цикла выбора КА
    [snr, ind_KA] = max(mean(phData.SignalToNoise));  % Поиск максимального отношения с/ш
    if(snr > 40)                                      % Для завершения поиска требуется отношение с/ш больше 40 dBHz
        fprintf('\n OK:  best KA is %d,    SNR = %5.1f dBHz\n', ind_KA, snr)
        break
    else
        fprintf('\n Failed: max SNR = %5.1f dBHz\n', snr)
    end
end
fclose(stream);  % Поиск подходящего КА завершён

% Выделение памяти для данных
phData.SignalToNoise = nan;
phData.SignalToNoise(1:phData.NumPointPlot, 1) = nan;

if (fead_data_from=='GEOS')
    fopen(stream);
else
    stream=fopen(name_bin_file);
end

while (1) % обработка данных с заданного КА
            %    fclose(stream);
            %    clc
            %    fopen(stream);
            %    for(open_close_port=1:33)

    
    % Ожидание пакета 16 (0x10) - Измерительная информация каналов
    [Bin.PH_data, phData.datN]=GEOS_3R_BIN_DataRead(hex2dec('10'), stream);
    
    % Ожидание пакета 19 (0x13) - Вектор состояния НЗ
    [Bin.navi_task, tmp]=GEOS_3R_BIN_DataRead(hex2dec('13'), stream);
    
    while (1)  % Обработка сообщений 0х10 и 0х13
        fprintf('\n ____________0x10___________')
        
        for m=1:phData.NumPointPlot-1     % смещаемся на такт вниз
            phData.phase(phData.NumPointPlot-m+1,1)=phData.phase(phData.NumPointPlot-m,1);
            phData.SignalToNoise(phData.NumPointPlot-m+1,1)=phData.SignalToNoise(phData.NumPointPlot-m,1);
            phData.reliable(phData.NumPointPlot-m+1,1)=phData.reliable(phData.NumPointPlot-m,1);
            phData.time(phData.NumPointPlot-m+1,1)=phData.time(phData.NumPointPlot-m,1);
            phData.cycle_d(phData.NumPointPlot-m+1,1)=phData.cycle_d(phData.NumPointPlot-m,1);
            t_gps(phData.NumPointPlot-m+1,1)=t_gps(phData.NumPointPlot-m,1);%0x13
        end
        
        % Выдение данных для требуемого КА
        [ phData.UTC,               ...   % Время UTC с 1 января 2008 года (стандартное для Геос)
          phData.cycle_d(1,1),      ...   % Количество тактов АЦП на текущем измерительном интервале
          phData.kol_vo_KA,         ...   % Количество КА в пакете 0x10
          phData.SignalToNoise(1),  ...   % Отношение сигнал/шум
          phData.phase(1),          ...   % Фаза
          phData.Doppler,           ...   % Смещение частоты
          phData.H_liter        ] = ...   % ?
            GEOS_3R_BIN_KA_data_0x10( Bin.PH_data,  ind_KA);
        
        if (StartTime<0)                  % Задаём начальное время (для графиков)
            StartTime = phData.UTC;

            if (ind_KA < 65)              % Несущая частота сигнала
                F_signal = F0_gps;
            else
                F_signal = F0_gln+phData.H_liter*dF_gln;
            end
        end
        
        phData.time(1,1) = (phData.UTC-StartTime); % по НС определяем
                                                   %            MEAN = mean(phData.cycle_d);
                                                   %            ind = find(abs(phData.cycle_d-MEAN)<0.5);
                                                   %            phData.mean_Fd=mean(phData.cycle_d(ind));
                                                   %            phData.TIME= phData.time+(phData.cycle_d(1,1)-phData.mean_Fd)/phData.mean_Fd;
        
        fprintf('\n UTC (01.01.2008): %9.0f sec', phData.UTC);
        fprintf('\n number KA: %d', phData.kol_vo_KA);
        
        t_gps(1,1) = GEOS_3R_BIN_navi_task_0x13(Bin.navi_task);%0x13
        break;
    end

    %обработка данных:
    if(sum(~isnan(phData.phase))>3)
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








