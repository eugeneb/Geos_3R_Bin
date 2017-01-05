function [ data, datN ] = GEOS_3R_BIN_DataRead(ncmd, stream)
% function [ data, datN ] = GEOS_3R_BIN_DataRead(ncmd, stream)
% 
% ������ ������� ������ �� �������� ������ ����� � ���������� ����
% ������� ���������:
%   ncmd    - ��� ���������� ������
%   stream  - ������� ����� ������ (���� ��� ����)
% �������� ���������:
%   data    - ���������� ������ (�����)
%   datN    - ���������� ����������� ������

    data = [];
    datN = 0;
    
    while ((~isreal(stream)) || (~feof(stream)))
        [cmd, ndat, dat] = Geos3_GetPacket(stream);
        
        if ((cmd == ncmd) && (length(dat) == ndat))
            % ������������ ������ � ������������ � Little Endian
            data = zeros(1, 4*ndat);
            for i=1:ndat
                for j=1:4
                    data((i-1)*4 + j) = mod(floor(dat(i)/2^(8*(j-1))), 2^8);
                end
            end
            data = data';
            datN = 4*ndat;
            return;
        end
    end
    
