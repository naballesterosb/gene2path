#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
import os
import numpy
import scipy.stats
from copy import *
import math
#from pylab import *

class AgilentParser:
		
	def __init__( this, iFileName ):
		
		this.dataFEATURES = {}
		
		iFile = file( iFileName, "r" )
		lines = iFile.read().splitlines()
		iFile.close()
		
		locFEATURES = False
		labelsFEATURES = []
		
		nLine=0
		while( nLine < len(lines) ):
			tokens = lines[nLine].split()
			
			if( locFEATURES == True ):
				if( len( this.dataFEATURES ) == 0 ):
					for i in range(0,len(tokens)):
						this.dataFEATURES[ labelsFEATURES[i] ] = [ tokens[i] ]
				else:
					for i in range(0,len(tokens)):
						this.dataFEATURES[ labelsFEATURES[i] ].append( tokens[i] )
					
			if( tokens[0] == "FEATURES" ):
				locFEATURES = True
				labelsFEATURES = tokens
				
			nLine += 1
			
	def get( this, label, dtype=None ):
		if( dtype == None ):
			return this.dataFEATURES[label]
		else:
			return numpy.asarray( this.dataFEATURES[label], dtype=dtype )
			
	def filterStringColumn( this, column, rex=None ):
		indexVec = []
		
		for i in range(0,len(column)):
			if( column[i][0:2] == rex ):
				indexVec.append( i )
				
		return indexVec
		
	def filterColumn( this, column, iVec ):
		effColumn = []
		for i in iVec:
			effColumn.append( column[i] )
				
		return effColumn
		
	def filterColumn( this, column, iVec ):
		effColumn = []
		for i in iVec:
			effColumn.append( column[i] )
				
		return effColumn
	
class MicroArray:
	def __init__( this ):
		this.title = "Unknown"
		this.nReplicas = -1
		this.nGenes = -1
		this.geneName = []
		
	def load( this, iFileName ):
		iFile = file( iFileName, "r" )
		lines = iFile.read().splitlines()
		iFile.close()
		
		this.geneName = []
		
		signal = []
		control = []
		
		nReplicas = 0
		loadGeneList=1
		column = []
		iVec = []
		
		nLine=0
		currentGroup = ""
		while( nLine < len(lines) ):
			tokens = lines[nLine].split()
			
			if( len(tokens) != 0 ): # ignore whitespaces
				if( tokens[0] == "TITLE" ):
					currentGroup = "TITLE"
					nLine += 1
					continue
					
				if( tokens[0] == "SIGNAL" ):
					currentGroup = "SIGNAL"
					nLine += 1
					continue
					
				if( tokens[0] == "CONTROL" ):
					currentGroup = "CONTROL"
					nLine += 1
					continue
					
				if( currentGroup == "TITLE" ):
					this.title = lines[nLine]
					#print "Loading: ", this.title
					
				if( currentGroup == "SIGNAL" ):
					parser = AgilentParser( tokens[0] )
					
					if( loadGeneList == 1 ):
						column = parser.get( "genename" )
						#iVec = parser.filterStringColumn( column, "JC" )
						
						#effColumn = parser.filterColumn( column, iVec )
						#this.geneName = effColumn[0:len(effColumn)/2]
						this.geneName = column[0:len(column)/2]
						loadGeneList = 0
					
					column = parser.get( "gProcessedSignal", numpy.float32 )
					
					effCol = column[0:len(column)/2]
					#effCol = effCol/sum( effCol )
					signal.append( effCol )
					
					effCol = column[len(column)/2:len(column)]
					#effCol = effCol/sum( effCol )
					signal.append( effCol )
					
					nReplicas += 2
					
					#effCol = (column[0:len(column)/2]+column[len(column)/2:len(column)])/2
					##effCol = effCol/sum( effCol )
					#signal.append( effCol )
					
					#nReplicas += 1
					
				if( currentGroup == "CONTROL" ):
					parser = AgilentParser( tokens[0] )
					column = parser.get( "gProcessedSignal", numpy.float32 )
					
					effCol = column[0:len(column)/2]
					#effCol = effCol/sum( effCol )
					control.append( effCol )
					
					effCol = column[len(column)/2:len(column)]
					#effCol = effCol/sum( effCol )
					control.append( effCol )
					
					#effCol = (column[0:len(column)/2]+column[len(column)/2:len(column)])/2
					##effCol = effCol/sum( effCol )
					#control.append( effCol )
					
			nLine += 1
			
		this.nGenes = len( this.geneName )
		this.nReplicas = nReplicas
			
		return ( signal, control )
		
	def average( this, vals, cutoff=1.0 ):
		matrixVals = numpy.asarray( vals ).transpose()
		
		averVec = []
		stdVec = []
		effVals = []
		
		for i in range(0,len(matrixVals)):
			aver = numpy.average( matrixVals[i,:] )
			std = numpy.std( matrixVals[i,:] )
			
			# Removing outliers
			effVec = []
			for j in range(0,len(matrixVals[0])):
				if( abs(matrixVals[i,j]-aver) <= cutoff*std ):
					effVec.append( matrixVals[i,j] )
					
			effVals.append( effVec )
			averVec.append( numpy.average( effVec ) )
			stdVec.append( numpy.std( effVec ) )
			
		return (averVec, stdVec, effVals)
		
	def makeFolds( this, signal, averControls ):
		folds = copy(signal)
		
		for i in range(0,this.nReplicas):
			for j in range(0,this.nGenes):
				folds[i][j] = folds[i][j]/averControls[j]
				
		return folds
			
def main():
	
	if( len(sys.argv) < 2 ):
		print "Usage:"
		print "      $ microarray.py inputFile gCutoff"
		quit()
	
	marray = MicroArray()
	(signal,control) = marray.load( sys.argv[1] )
	
	gCutoff = 1.0
	if( len(sys.argv) > 2 ):
		gCutoff = float(sys.argv[2])
	
	# Elimina los genes desconocidos
	#signal = numpy.delete( signal, range(3104,6416), 1 )
	#control = numpy.delete( control, range(3104,6416), 1 )
	#marray.geneName = numpy.delete( marray.geneName, range(3104,6416) )
	#marray.nGenes = len(marray.geneName)
	
	# Para depurar
	dd = None
	#dd=2816-1
	
	if( dd != None ):
		print "NAME        = ", marray.geneName[dd]
		print "SIGNAL      = ", signal[0][dd], signal[1][dd], signal[2][dd], signal[3][dd]
	
	if( len(signal[0]) != len(control[0]) ):
		print "Size of the vectors SIGNAL and CONTROL are not equal (", len(signal[0]), ", ", len(control[0]), ")"
		quit()
	
	# Normaliza el array
	for i in range(0,len(signal)):
		sumSignal = sum(signal[i])/100000000.0
		sumControls = sum(control[i])/100000000.0
		
		for j in range(0,len(signal[i])):
			signal[i][j] = signal[i][j]/sumSignal
			control[i][j] = control[i][j]/sumControls
		
	if( dd != None ):
		print "SIGNALNorm  = ", signal[0][dd], signal[1][dd], signal[2][dd], signal[3][dd]
		print "CONTROL     = ", control[0][dd], control[1][dd], control[2][dd], control[3][dd]
		
	(aver, std, effSignals) = marray.average( signal, 1.0 )
	(aver, std, effControls) = marray.average( control, 2.0 )
	
	if( dd != None ):
		print "CONTROL'    = ", effControls[dd]
		print "averCONTROL = ", aver[dd]
	
	folds = marray.makeFolds( signal, aver )
	(aver, std, effFolds) = marray.average( folds, 1.0 )
	
	if( dd != None ):
		print "FOLD        = ", folds[0][dd], folds[1][dd], folds[2][dd], folds[3][dd]
		print "FOLD'       = ", effFolds[dd]
		print "averFOLD    = ", aver[dd]
		quit()
	
	#ofile = file("salida.txt", "w")
	
	#print >> ofile, "%10s"%"# GeneID", "%10s"%"g", "%10s"%"dg", "%10s"%"fup", "%10s"%"dfup", "%10s"%"fdown", "%10s"%"dfdown", "%10s"%"p-value", "%10s"%"t-test"
	#print "%10s"%"# GeneID", "%10s"%"g", "%10s"%"dg", "%10s"%"fup", "%10s"%"dfup", "%10s"%"fdown", "%10s"%"dfdown", "%10s"%"p-value", "%10s"%"t-test"
	
	print "%10s"%"# GeneID", "%10s"%"g", "%10s"%"dg", "%10s"%"p-value", "%10s"%"t-test"
	for i in range(0,marray.nGenes):
		g = math.log(aver[i])/math.log(2.0)
		dg = std[i]/(aver[i]*math.log(2.0))
		
		#fup = aver[i]
		#dfup = std[i]
		
		#fdown = -1.0/fup
		#dfdown = dfup/(fup**2)
		
		if( g >= gCutoff or g <= -gCutoff ):
			#print >> ofile, "%10s"%marray.geneName[i], "%10.2f"%g, "%10.2f"%dg, "%10.2f"%fup, "%10.2f"%dfup, "%10.2f"%fdown, "%10.2f"%dfdown, "%10.2f"%scipy.stats.ttest_ind( effSignals[i], effControls[i] )[1], "%10.2f"%scipy.stats.ttest_ind( effSignals[i], effControls[i] )[0]
			print "%10s"%marray.geneName[i], "%10.2f"%g, "%10.2f"%dg, "%10.2f"%scipy.stats.ttest_ind( effSignals[i], effControls[i] )[1], "%10.2f"%scipy.stats.ttest_ind( effSignals[i], effControls[i] )[0]
			
	#boxplot( effFolds[1:100] )
	#show()
	
	#a = [ [1,2,3,4], [5,3,2,1], [4,2,6,3] ]
	#amat = numpy.asarray( a )
	#amat2 = amat.transpose()
	#print amat2[0,:]
	
if __name__ == "__main__":
	main()
