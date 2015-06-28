/*新增加接收字节数探测
 * SPI testing only for (using spidev driver)
 * \file  -> spi_test.c
 * 
 * \version     1.0.0
 *
 * \date        2014年03月14日
 * 
 * \author      jiangdou  <jiangdouu88@126.com>
 *
 * Copyright (c) 2014 jiangdou. All Rights Reserved.
 */

//////////////////
//USAGE
/////////////////
//  - >sunxi@sunxi:~/$ gcc -o spi spi_.c 

#include <assert.h>
#include <errno.h>     
#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <linux/spi/spidev.h>
 
char buf[10];
char buf2[10];
 int com_serial;
 int failcount;
 
struct spi_ioc_transfer xfer[2];





////////////////////////
// Init SPIdev
///////////////////////
int spi_init(char filename[40])
{
        int file;
        __u8    mode, lsb, bits;
        __u32 speed=25000;
 
        if ((file = open(filename,O_RDWR)) < 0)
                {
                printf("Failed to open the bus.");
                /* ERROR HANDLING; you can check errno to see what went wrong */
                com_serial=0;
                exit(1);
                }
 
                ///////////////
                // Verifications
                ///////////////
                //possible modes: mode |= SPI_LOOP; mode |= SPI_CPHA; mode |= SPI_CPOL; mode |= SPI_LSB_FIRST; mode |= SPI_CS_HIGH; mode |= SPI_3WIRE; mode |= SPI_NO_CS; mode |= SPI_READY;
                //multiple possibilities using |
                /*
                        if (ioctl(file, SPI_IOC_WR_MODE, &mode)<0)       {
                                perror("can't set spi mode");
                                return;
                                }
                */
 
                        if (ioctl(file, SPI_IOC_RD_MODE, &mode) < 0)
                                {
                                perror("SPI rd_mode");
                                return;
                                }
                        if (ioctl(file, SPI_IOC_RD_LSB_FIRST, &lsb) < 0)
                                {
                                perror("SPI rd_lsb_fist");
                                return;
                                }
                //sunxi supports only 8 bits
                /*
                        if (ioctl(file, SPI_IOC_WR_BITS_PER_WORD, 8)<0)      
                                {
                                perror("can't set bits per word");
                                return;
                                }
                */
                        if (ioctl(file, SPI_IOC_RD_BITS_PER_WORD, &bits) < 0) 
                                {
                                perror("SPI bits_per_word");
                                return;
                                }
                /*
                        if (ioctl(file, SPI_IOC_WR_MAX_SPEED_HZ, &speed)<0)      
                                {
                                perror("can't set max speed hz");
                                return;
                                }
                */
                        if (ioctl(file, SPI_IOC_RD_MAX_SPEED_HZ, &speed) < 0) 
                                {
                                perror("SPI max_speed_hz");
                                return;
                                }
         
 
        printf("%s: spi mode %d, %d bits %sper word, %d Hz max\n",filename, mode, bits, lsb ? "(lsb first) " : "", speed);
 
        //xfer[0].tx_buf = (unsigned long)buf;
        xfer[0].len = 2; /* Length of  command to write*/
        xfer[0].cs_change = 0; /* Keep CS activated */
        xfer[0].delay_usecs = 1000, //delay in us
        xfer[0].speed_hz = 2500000, //speed
        xfer[0].bits_per_word = 2, // bites per word 8
 
        //xfer[1].rx_buf = (unsigned long) buf2;
        xfer[1].len = 1; /* Length of Data to read */
        xfer[1].cs_change = 0; /* Keep CS activated */
        xfer[0].delay_usecs = 0;
        xfer[0].speed_hz = 2500000;
        xfer[0].bits_per_word = 2;
 
        return file;
}
 

////////////////////////////////////////
// Read n bytes from the 1 bytes add
///////////////////////////////////////
int spi_read(int add,int file)
{         
	int status;
	char temp;
	memset(buf, 0, sizeof(buf));
	memset(buf2, 0, sizeof(buf2));
	buf[0] = 0x03;	//03 ->读命令
	buf[1] = add;
	//buf[2] = add2;
	xfer[0].tx_buf = (unsigned long)buf;
	xfer[0].len = 2; /* Length of  command to write*/
	xfer[1].rx_buf = (unsigned long) buf2;
	xfer[1].len = 1; /* Length of Data to read */
	status = ioctl(file, SPI_IOC_MESSAGE(2), xfer);
	if (status < 0)
	{
		perror("SPI_IOC_MESSAGE"); 
		return;
	}
	//printf("env: %02x %02x %02x\n", buf[0], buf[1], buf[2]);
	//printf("ret: %02x %02x %02x %02x\n", buf2[0], buf2[1], buf2[2], buf2[3]);
	com_serial=1;
	failcount=0;
	
	temp = buf2[0];
	return temp;
} 


////////////////////////////////////////////////////////
// Write n bytes int the 1 bytes address add 
///////////////////////////////////////////////////////
//void spi_write(int cmd,int add,int nbytes,char value[10],int file)
void spi_write(int cmd,int add,int nbytes,char value[10],int file)
{         
	unsigned char   buf[32], buf2[32];
	int status;
	memset(buf, 0, sizeof(buf));
	memset(buf2, 0, sizeof(buf2));
	buf[0] = cmd;	//02 ->写命令
	buf[1] = add;
	//buf[2] = add2;
	if (nbytes>=1) buf[2] = value[0];
	if (nbytes>=2) buf[3] = value[1];
	if (nbytes>=3) buf[4] = value[2];
	if (nbytes>=4) buf[5] = value[3];
	xfer[0].tx_buf = (unsigned long)buf;
	xfer[0].len = nbytes+2; /* Length of  command to write*/
	status = ioctl(file, SPI_IOC_MESSAGE(1), xfer);
	if (status < 0)
	{
		perror("SPI_IOC_MESSAGE"); 
		return;
	}         
	//printf("env: %02x %02x %02x\n", buf[0], buf[1], buf[2]);
	//printf("ret: %02x %02x %02x %02x\n", buf2[0], buf2[1], buf2[2], buf2[3]);
	com_serial=1;
	failcount=0;
}

///////////////////////////////////
//初始化MCP2515
//////////////////////////////////
int init_mcp2515(int file)
{
	char bufw[10];
	char temp[20];
	char *buffer;
	
	//spi_set(file)；//复位MCP2515 ->复位指令 :11000000	->0xc0;
	memset(bufw, 0, sizeof(bufw));
	bufw[0] = 0x0;
	spi_write(0xC0,0x0,1,bufw,file);
	usleep(80000);
	
	//buffer = spi_read(0x2C,file); //reading the address 0xE60E
	//printf("read data at address 0x0f: %02x %02x \n\r", buffer[0], buffer[1]);
	
	bufw[0] = 0xE0;		//1110,0000
	bufw[1] = 0x80;		//100x,xxxx
	spi_write(0x05,0x0f,2,bufw,file);//设置MCP2515为配置模式
	temp[0] = spi_read(0x0F,file);
	printf("address 0x2F 4 wei1 is %02x\n\r", temp[0]);
	
	////TJA1050 最低波特率为60K
	//设置通信的速率 16M 晶振 500k
	memset(bufw, 0, sizeof(bufw));
	bufw[0] = 0x00;
	spi_write(0x02,0x2A,1,bufw,file);
	
	memset(bufw, 0, sizeof(bufw));
	bufw[0] = 0xB8;
	spi_write(0x02,0x29,1,bufw,file);
	
	memset(bufw, 0, sizeof(bufw));
	bufw[0] = 0x05;
	spi_write(0x02,0x28,1,bufw,file);
	
	//0x00  仅接收标准或扩展标识符  
	//0x60  关闭接收所有数据
	memset(bufw, 0, sizeof(bufw));
	bufw[0] = 0x60;
	spi_write(0x02,0x60,1,bufw,file);
	
	//滤波
	memset(bufw, 0, sizeof(bufw));
	spi_write(0x02,0x00,1,bufw,file);
	spi_write(0x02,0x01,1,bufw,file);
	spi_write(0x02,0x02,1,bufw,file);
	spi_write(0x02,0x03,1,bufw,file);
	//屏蔽
	spi_write(0x02,0x20,1,bufw,file);
	spi_write(0x02,0x21,1,bufw,file);
	spi_write(0x02,0x22,1,bufw,file);
	spi_write(0x02,0x23,1,bufw,file);
	
	//禁用引脚发送功能
	memset(bufw, 0, sizeof(bufw));
	bufw[0] = 0x07;
	bufw[1] = 0x0;
	spi_write(0x05,0x0D,2,bufw,file);
	
	//接收数据产生中断
	memset(bufw, 0, sizeof(bufw));
	bufw[0] = 0x01;	//01为接收中断 81为错误中断
	spi_write(0x02,0x2B,1,bufw,file);
	temp[0] = spi_read(0x2B,file);
	printf("address 0x2B 4 wei1 is %02x\n\r", temp[0]);

	//回环模式 
	//工作模式 
	memset(bufw, 0, sizeof(bufw));
	bufw[0] = 0xE4;
	bufw[1] = 0x0;
	spi_write(0x05,0x0F,2,bufw,file);		//0000,
	temp[0] = spi_read(0x0F,file);
	printf("address 0x0F 4 wei1 is %02x\n\r", temp[0]);
	
	printf("init_mcp2515 OK\n\r");

}


/////////////////////////////////////////////
//mcp2515_spi数据发送
////////////////////////////////////////////
int CAN_Send(int file)
{
	unsigned int i;
	char ii;
	char temp[20];
	char bufw[10];
	char com_recv[14] = {0x0B,0x0,0x0,0x0,0x0,0x08,0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88};
	//  调试报文
	//  0B00000000081122334455667788
	//(0B写0B到0x30) + (00 00 00 00标识符) + (08字节数) + (1122334455667788发送的数据)
	for(i=1;i < 14;i++)
	{	
		bufw[0] = com_recv[i];
		spi_write(0x02,0x30 + i,1,bufw,file);
		printf("data is: %02x\n", com_recv[i]);
		usleep(100);
	}
	printf("\n");
	for(i=0;i < 8;i++)
	{	
		
		temp[0] = spi_read(0x36 + i,file);
		printf("data is: %02x\n", temp[0]);
		usleep(100);
	}
	printf("\n");
	
	bufw[0] = 0x03;	//00001011
	bufw[1] = com_recv[0];
	spi_write(0x05,0x30,2,bufw,file);	//写发送命令
	
	bufw[0] = com_recv[0];	//00001011
	bufw[1] = com_recv[0];
	
	temp[0] = spi_read(0x30,file);
	printf("address 0x30 4 wei1 is %02x\n\r", temp[0]);
	
	spi_write(0x05,0x30,2,bufw,file);	//写发送命令
	sleep(1);
	temp[0] = spi_read(0x30,file);
	printf("address 0x30 4 wei2 is %02x\n\r", temp[0]);// 观察发送请求位
	//spi_write(0x05,0x30,2,bufw,file);
	
	printf("\n");
	temp[0] = spi_read(0x37,file);
	printf("address 0x37: %02x\n", temp[0]);
	temp[0] = spi_read(0x3D,file);
	printf("address 0x3D: %02x\n", temp[0]);
	printf("\n");
	
	
	
	sleep(1);
	temp[0] = spi_read(0x30,file);
	printf("address 0x30 4 wei2 is %02x\n\r", temp[0]);// 观察发送请求位
#if 0
	do
	{	
		temp[0] = spi_read(0x30,file);// 读发送缓存0控制寄存器 //判断0x30寄存器第4为0
		ii = temp[0];
		ii = ii & 0x08; 	// 观察发送请求位
		printf("address 0x30 4 wei3 is %02x\n\r", ii);
	}while(ii); 
#endif
	
	return 1;
}


/////////////////////////////////////////////
//mcp2515_spi数据发送
////////////////////////////////////////////
char *CAN_read(int file)
{	
	unsigned int i;
	char tmp;
	char bufw[10];
	static char temp2[20];
	static char *p = temp2
	//printf("mcp2515 receive data\n\r");
	tmp = spi_read(0x2C,file);	/* 读中断标志寄存器 */
	
	memset(bufw, 0, sizeof(bufw));
	memset(temp2, 0, sizeof(temp2));
	spi_write(0x02,0x2C,1,bufw,file);    /* 清除所有中断标志位 */	
#if 0
	if(tmp & 0x01)
	{
		for(i=0;i<14;i++)
		{	
			(temp2 + i) = spi_read(0x60+i,file);
			printf("mcp2515_receive_data %d :%02x\n",i,temp2[0]);
		}

	}
#endif
	if(tmp & 0x01)
	{
		for(i=0;i<14;i++)
		{	
			temp2[i] = spi_read(0x60+i,file);
			//temp2 = temp2 + i;
			
		}

	}
	//printf("%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x\n",temp2[0],temp2[1],temp2[2],temp2[3],temp2[4],temp2[5],temp2[6],temp2[7],temp2[8],temp2[9],temp2[10],temp2[11],temp2[12],temp2[13]);
	return p;
}


//////////////////////////////////////
////gpio初始化
//////////////////////////////////////



///////////////////////////////
////读gpio中断标志
//////////////////////////////

////////////////////////////////////////////////////
//main
////////////////////////////////////////////////////
int main(void)
{
	int ret = 0;
	char *temprd;
	int fd;
	int a,i;	//gpio中断标志
	
	
	
	/////
	//spi_init初始化
	/////
	fd = spi_init("/dev/spidev0.0"); //dev	spi_init初始化
	
	
	/////
	//初始化MCP2515
	////
	init_mcp2515(fd);
	
	//memset(temprd, 0, sizeof(temprd));
	
#if 0
	//////
	//mcp2515发送数据
	//////
	int rets = CAN_Send(fd);	//mcp2515发送数据
	if (rets == 0)
		printf("CAN_Send send error\n\r");
		
	usleep(1000);
#endif
	
#if 1
	int byte = 0;//接收数据字节个数
/////////////////////////////////////
//检测mcp2515接收数据INT
/////////////////////////////////////
	while(1)
	{	
		
		
		//printf("a is %d\n\r",a);
		
		
		case 0:
			//printf("mcp2515 receive data\n");
			temprd = CAN_read(fd);
		
		baye = *(temprd + 6);
		printf("baye is %d\n",baye);
		printf("%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x\n",*temprd,*(temprd + 1),*(temprd + 2),*(temprd + 3),*(temprd + 4),*(temprd + 5),*(temprd + 6),*(temprd + 7),*(temprd + 8),*(temprd + 9),*(temprd + 10),*(temprd + 11),*(temprd + 12),*(temprd + 13));
		//free(temprd);

		if(byte!=0)	
		{
			switch (byte) 
			{	
		//	case 0:
			//printf("mcp2515 receive data\n");
			
		//		break;
			case 1:
				printf("%02x %02x %02x %02x %02x %02x %02x\n",*temprd,*(temprd + 1),*(temprd + 2),*(temprd + 3),*(temprd + 4),*(temprd + 5),*(temprd + 6));
				break;
			case 2:
				printf("%02x %02x %02x %02x %02x %02x %02x %02x\n",*temprd,*(temprd + 1),*(temprd + 2),*(temprd + 3),*(temprd + 4),*(temprd + 5),*(temprd + 6),*(temprd + 7));
				break;
			case 3:
				printf("%02x %02x %02x %02x %02x %02x %02x %02x %02x\n",*temprd,*(temprd + 1),*(temprd + 2),*(temprd + 3),*(temprd + 4),*(temprd + 5),*(temprd + 6),*(temprd + 7),*(temprd + 8));
				break;
			case 4:
				printf("%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x\n",*temprd,*(temprd + 1),*(temprd + 2),*(temprd + 3),*(temprd + 4),*(temprd + 5),*(temprd + 6),*(temprd + 7),*(temprd + 8),*(temprd + 9));
				break;
			case 5:
				printf("%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x\n",*temprd,*(temprd + 1),*(temprd + 2),*(temprd + 3),*(temprd + 4),*(temprd + 5),*(temprd + 6),*(temprd + 7),*(temprd + 8),*(temprd + 9),*(temprd + 10));
				break;
			case 6:
				printf("%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x\n",*temprd,*(temprd + 1),*(temprd + 2),*(temprd + 3),*(temprd + 4),*(temprd + 5),*(temprd + 6),*(temprd + 7),*(temprd + 8),*(temprd + 9),*(temprd + 10),*(temprd + 11));
				break;
			case 7:
				printf("%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x\n",*temprd,*(temprd + 1),*(temprd + 2),*(temprd + 3),*(temprd + 4),*(temprd + 5),*(temprd + 6),*(temprd + 7),*(temprd + 8),*(temprd + 9),*(temprd + 10),*(temprd + 11),*(temprd + 12));
				break;
			case 8:
				printf("%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x\n",*temprd,*(temprd + 1),*(temprd + 2),*(temprd + 3),*(temprd + 4),*(temprd + 5),*(temprd + 6),*(temprd + 7),*(temprd + 8),*(temprd + 9),*(temprd + 10),*(temprd + 11),*(temprd + 12),*(temprd + 13));
				break;
			default:
				break;
		
			}
				
		}

			break;
		case 1:
			break;
		default:
			break;
		
		
	usleep(8000);
	
	}
	
#endif
	return ret;
}




