clear
clc

%fclose(instrfind)

%fead_data_from='GEOS';
fead_data_from='file';

if (fead_data_from=='GEOS')      % ��������� �� �����
    Num_com_port = 'COM67';   
    baud = 115200;
    stream = serial(Num_com_port, 'BaudRate', baud);
else                             % ������ �� �����
    name_bin_file = 'bin_data_file/geos_3MR_F_1_Hz.bin';
    stream = fopen(name_bin_file, 'r');
end


% ��� ������������
phData.NumPointPlot=30;          % ������������ ����� ����� �� �������
phData.NumPointPoiskKA=5;        % ����� ����� ��� ������ ������� ��
phData.chisl_spytnicov=96;       % ����� ��������� 

% ���������:
F0_gps=1.57542e9;                % ����������� ������� gps
F0_gln=1.602e9;                  % ����������� ������� �������
dF_gln=562500;                   % ��� �� ������� ������� (���, ������)
c=299792458;                     % �������� �����

% ��������� ������ ��� ������� ��� ������
phData.reliable(1:phData.NumPointPlot,1:phData.chisl_spytnicov) = nan; 
phData.SignalToNoise(1:phData.NumPointPoiskKA,1:phData.chisl_spytnicov) = nan;
phData.phase(1:phData.NumPointPlot,1) = nan;
phData.time(1:phData.NumPointPlot,1) = nan;
phData.H_liter = nan;
phData.cycle_d(1:phData.NumPointPlot,1) = nan;
t_gps(1:phData.NumPointPlot,1) = nan;

if(fead_data_from=='GEOS')       % ��� ��� GEOS-3R
                                 % ��������� ��������� ��������� ���������
                                 % ������ ��������� 0�10 � 0x13

    % �������� ������ 0x4F - ���������� �������� ���������
    Bin.data_write(1:8,1)=[hex2dec('4F'); 0; 1; 0; 0; 0; 9; 0];
    GEOS_3R_BIN_DataWrite(Bin.data_write, stream);
    
    % �������� ������ 0x44 - ���� ������ (1 ��)
    Bin.data_write(1:8,1)=[hex2dec('44'); 0; 1; 0; 3; 0; 0; 0];
    GEOS_3R_BIN_DataWrite(Bin.data_write, stream);
    
    fopen(stream);
end

StartTime=-1; % ����� ������ ������

while (1)    % �������� ��, � ������� ������ ����� ��������
    for ch=1:phData.NumPointPoiskKA
        % ���������� ������ 16 (0x10) - ������������� ���������� ������� 
        
        [Bin.PH_data, phData.datN] = GEOS_3R_BIN_DataRead(16, stream);
        
        % �������������� ����� "���������� ��"
        phData.NumKA=GEOS_3R_BIN_bin2num(Bin.PH_data(13:16,1), 'int');
        fprintf('NUM KA: %d  \n', phData.NumKA)
        
        for k=1:phData.NumKA      % ��������� ���� ��������� �� ������ 0x10

            % ������ ����, ���������� �� ������� k � ������ 0x10
            rec_ind = 4*(-9+14*k)-3:4*(4+14*k);

            % ��������� ��������� ���� �� �� ������ 0x10
            [phData.tmp_KAnumber        ...   % ����� ��
             phData.tmp_reliable        ...   % ����� �������������
             phData.tmp_SignalToNoise   ...   % q, ����
             phData.tmp_phase           ...   % ����
             phData.tmp_Doppler     ] = ...   % �������� �������
                GEOS_3R_BIN_DataDecod_0x10( Bin.PH_data(rec_ind, 1) );
            
            % ���������� ������� ���������� ������/���
            phData.SignalToNoise(ch, phData.tmp_KAnumber) = phData.tmp_SignalToNoise;
        end
        
    end
    
    % ������� ������ �� ����� ������ ��
    [snr, ind_KA] = max(mean(phData.SignalToNoise));  % ����� ������������� ��������� �/�
    if(snr > 40)                                      % ��� ���������� ������ ��������� ��������� �/� ������ 40 dBHz
        fprintf('\n OK:  best KA is %d,    SNR = %5.1f dBHz\n', ind_KA, snr)
        break
    else
        fprintf('\n Failed: max SNR = %5.1f dBHz\n', snr)
    end
end
fclose(stream);  % ����� ����������� �� ��������

% ��������� ������ ��� ������
phData.SignalToNoise = nan;
phData.SignalToNoise(1:phData.NumPointPlot, 1) = nan;

if (fead_data_from=='GEOS')
    fopen(stream);
else
    stream=fopen(name_bin_file);
end

while (1) % ��������� ������ � ��������� ��
            %    fclose(stream);
            %    clc
            %    fopen(stream);
            %    for(open_close_port=1:33)

    
    % �������� ������ 16 (0x10) - ������������� ���������� �������
    [Bin.PH_data, phData.datN]=GEOS_3R_BIN_DataRead(hex2dec('10'), stream);
    
    % �������� ������ 19 (0x13) - ������ ��������� ��
    [Bin.navi_task, tmp]=GEOS_3R_BIN_DataRead(hex2dec('13'), stream);
    
    while (1)  % ��������� ��������� 0�10 � 0�13
        fprintf('\n ____________0x10___________')
        
        for m=1:phData.NumPointPlot-1     % ��������� �� ���� ����
            phData.phase(phData.NumPointPlot-m+1,1)=phData.phase(phData.NumPointPlot-m,1);
            phData.SignalToNoise(phData.NumPointPlot-m+1,1)=phData.SignalToNoise(phData.NumPointPlot-m,1);
            phData.reliable(phData.NumPointPlot-m+1,1)=phData.reliable(phData.NumPointPlot-m,1);
            phData.time(phData.NumPointPlot-m+1,1)=phData.time(phData.NumPointPlot-m,1);
            phData.cycle_d(phData.NumPointPlot-m+1,1)=phData.cycle_d(phData.NumPointPlot-m,1);
            t_gps(phData.NumPointPlot-m+1,1)=t_gps(phData.NumPointPlot-m,1);%0x13
        end
        
        % ������� ������ ��� ���������� ��
        [ phData.UTC,               ...   % ����� UTC � 1 ������ 2008 ���� (����������� ��� ����)
          phData.cycle_d(1,1),      ...   % ���������� ������ ��� �� ������� ������������� ���������
          phData.kol_vo_KA,         ...   % ���������� �� � ������ 0x10
          phData.SignalToNoise(1),  ...   % ��������� ������/���
          phData.phase(1),          ...   % ����
          phData.Doppler,           ...   % �������� �������
          phData.H_liter        ] = ...   % ?
            GEOS_3R_BIN_KA_data_0x10( Bin.PH_data,  ind_KA);
        
        if (StartTime<0)                  % ����� ��������� ����� (��� ��������)
            StartTime = phData.UTC;

            if (ind_KA < 65)              % ������� ������� �������
                F_signal = F0_gps;
            else
                F_signal = F0_gln+phData.H_liter*dF_gln;
            end
        end
        
        phData.time(1,1) = (phData.UTC-StartTime); % �� �� ����������
                                                   %            MEAN = mean(phData.cycle_d);
                                                   %            ind = find(abs(phData.cycle_d-MEAN)<0.5);
                                                   %            phData.mean_Fd=mean(phData.cycle_d(ind));
                                                   %            phData.TIME= phData.time+(phData.cycle_d(1,1)-phData.mean_Fd)/phData.mean_Fd;
        
        fprintf('\n UTC (01.01.2008): %9.0f sec', phData.UTC);
        fprintf('\n number KA: %d', phData.kol_vo_KA);
        
        t_gps(1,1) = GEOS_3R_BIN_navi_task_0x13(Bin.navi_task);%0x13
        break;
    end

    %��������� ������:
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
    
    %����� ��������:
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








