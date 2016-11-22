function [ OUT ] = GEOS_3R_BIN_bin2num( IN, format )
% function [ OUT ] = GEOS_3R_BIN_bin2num( IN, format )
%
% ������ ������� ����������� ������ �� �������� � ��������� ������
% ������� ���������:
%    IN     - ������� �����
%    format - ��������� ������ (double, int, float)
% �������� ���������:
%    OUT    - �������� �����
    
% ���� ��������� �� �������� � ��������
    
    Input=IN;
    IN=str2num(dec2bin(IN)); % �������� ����� � �������� �������������
    if(length(format)==length('double'))
        while(format=='double')
            Mant=0;
            expon=0;
            znak=0;
            for(k=1:6)
                Mant=Mant+Input(k)*2^(8*(k-1));
            end
            Mant=Mant+mod(Input(7),2^4)*2^48;
            Mant=Mant*2^-52;
            expon=fix(Input(7)/2^4);
            expon=expon+mod(Input(8),2^7)*2^4;
            znak=fix(Input(8)/2^7);
            OUT=(-1)^znak*(1+Mant)*2^(expon-1023);
            break;
        end
    end
    
    if(length(format)==length('int'))
        while(format=='int')
            A(1:32)=0;
            for(k=1:4) % ������������ ����� �� �����
                for(m=1:8)
                    A(m+8*(k-1))=fix(mod(IN(k),10^m)/10^(m-1));
                end
            end
            
            OUT=A(32); %��������� 
            for(k=1:31)% ������ �����             ������=�����(�(k)*2^(k-1)) - ������������� �����
                OUT=OUT+abs(A(k)-A(32))*2^(k-1); % ������=1+�����(|�(k)-1|*2^(k-1)) - ���. �����
            end
            OUT=((-1)^A(32))*OUT; %��������� ����
            
            break;
        end
    end

    if(length(format)==length('float'))
        while(format=='float')
            A(1:32)=0;
            for(k=0:3) % ������������ ����� �� �����
                for(m=1:8)
                    A(m+8*k)=fix(mod(IN(k+1),10^m)/10^(m-1));
                end
            end
            
            Man=0; %��������
            for(k=1:23)
                Man=Man+A(24-k)*2^(-k);
            end
            
            expon=0; % �������
            for(k=1:8)
                expon=expon+A(23+k)*2^(k-1);
            end
            
            OUT=(-1)^(A(32))*(1+Man)*2^(expon-127);
            break;
        end
    end
    
end

