import threading
import time	

def newSocket():

		return __LinuxL2CAPSocket()
		
		
class __LinuxL2CAPSocket:
	"""Linux L2CAP wrapper"""
	from bluetooth import BluetoothSocket,L2CAP	
	def __init__(self):
		self.sock = self.BluetoothSocket( self.L2CAP )
	
	def connect(self,address,port):
		self.sock.connect((address,port))
		
	def close(self):
		self.sock.close()
		
	def receive(self,length):
		return self.sock.recv(length)
		
	def send(self,string):
		self.sock.send(string)
	

    
# WIIMOTE
class Wiimote(threading.Thread):

	def __init__(self,address):     
		from BluetoothSupport import newSocket
		self.address = address
		## Create two bluetooth sockets: 
		##              One to receive data,
		##              One to send config data
		self.receiveSocket = newSocket()
		self.sendSocket = newSocket()
		self.data = None
		self.updated = False
      
	def send(self, *data ):
		#for d in join( data ): print ord(d).__hex__()[2:],
		#print
		
		self.sendSocket.send( reduce(lambda x, y: x + chr(y),data,'') )
		    
	def getData(self):
		## self.data is kept current by __getData looping constantly
		if self.updated:
			self.updated = False
			return self.data
		else: return None
		    
	def disconnect(self):
		self.r = 0
		self.receiveSocket.close()
		self.sendSocket.close()	
		    
	def run(self):
		## Continually receive data from the wiimote to avoid backlog. 
		self.r = 1
		while self.r:
			self.__getData()
			
	def __getData(self):
			self.data =  self.receiveSocket.receive(19)
			self.updated = True
			
	def setLEDinBinary(self,n):
		"""Sets the LEDs on the wiimote to the binary representation of n"""
		self.send(0x52,0x11,int((n+1)<<4))
			
	def connect(self):
		""" Connects to the wiimote at address and enable IR
			for much more information and clarity, see
			http://wiibrew.org/index.php?title=Wiimote
		"""
		print("Trying to connect to %s" % self.address)
		## Port 19 is where the data will be found
		## Port 17 is the one we want to send our data on.
		self.receiveSocket.connect( self.address, 19 )
		self.sendSocket.connect( self.address, 17 )

		## So now we're connected!
		## The Data Reporting Mode is set by sending a two-byte command to Report 0x12: 
		self.send(0x52,0x12,0x00,0x33)
		## 0x00 sets non-continuous reporting
		## 0x33 enables data reporting mode to0x33, the one with IR data. 
		
		## The following procedure should be followed to turn on the IR Camera:

        ## 1. Enable IR Camera (Send 0x04 to Output Report 0x13)
        self.send(0x52,0x13,0x04);time.sleep(0.01)
		## 2. Enable IR Camera 2 (Send 0x04 to Output Report 0x1a)
		self.send(0x52,0x1a,0x04);time.sleep(0.01)
		## 3. Write 0x08 to register 0xb00030
		self. send(0x52,0x16,0x04,0xb0,0x00,0x30, 1, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );time.sleep(0.01)
		## 4. Write Sensitivity Block 1 to registers at 0xb00000
		self. send(0x52,0x16,0x4, 0xb0, 0x0, 0x6, 1, 0x90, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);time.sleep(0.01)
		self. send(0x52,0x16,0x4, 0xb0, 0x0, 0x8, 1, 0x41, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);time.sleep(0.01)
		## 5. Write Sensitivity Block 2 to registers at 0xb0001a
		self. send(0x52,0x16,0x4, 0xb0, 0x0, 0x1a, 1, 0x40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);time.sleep(0.01)
		## 6. Write Mode Number to register 0xb00033
		self. send(0x52,0x16,0x4, 0xb0, 0x0, 0x33, 1, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);time.sleep(0.01)
		## 7. Write 0x08 to register 0xb00030 (again) 
		self. send(0x52,0x16,0x4, 0xb0, 0x0, 0x30, 1, 0x08, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);time.sleep(0.01)

		## This turns the 1st led on. If the program runs and the LED remains off or flashing,
		## then there is a problem. 
		self.send(0x52,0x11,0x14) 

		## Set up and start the data-receiving thread
		threading.Thread.__init__ (self)
		
		self.start() 
		print "Connected to %s" % self.address
		return 1

	def vibrate(self, duration = 1):
		"""Vibrates the wiimote for 'duration' number of seconds"""
		t0 = time.time()
		## The 0x01 sets vibrate on any output register. 0x15 is 
		## a register we can write to safely without changing anything
		## important, its a request for status info. 
		self.send(0x52,0x15,0x01)
		time.sleep(duration)
		self.send(0x52,0x15,0x00)
		