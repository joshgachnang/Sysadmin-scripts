import os, subprocess, sys


def main(argv):
    run(argv)
    
def run(arg):
    """
    Runs the given arg at the command line using the default shell. Outputs
    when commands are run successfully.
    
    Based on http://developer.spikesource.com/wiki/index.php/How_to_invoke_subprocesses_from_Python
    
    @param Tuple args
      A tuple of args, with the first being the command to be run, and
      the remaining ones flags and arguments for the command. STDOUT and
      STDERR are piped to tuple, waiting until the output is finished,
      then writing both to the log file, if not empty.
      Ex. ['apt-get', '-y', 'install', 'dnsmasq'], which installs
      dnsmasq using apt-get, and assumes yes to questions.
    """
	
    # Open output and write some info about the command to be written, including
    # name of command and arguments.
    # This could be modified to adjust how much is printed via a DEBUG variable.
    with open(os.path.join(os.curdir, "output.log"), 'a') as outFile:
	outFile.write("Command: ")
	for a in arg:
	  outFile.write(a,)
	  outFile.write(" ")
	outFile.write("\n")
    # Open output and error log file and append to them the output of the commands
    with open(os.path.join(os.curdir, "output.log"), 'a') as outFile:
	with open(os.path.join(os.curdir, "error.log"), 'a') as errorFile:
	    # Call the subprocess using convenience method
	    
	    retval = subprocess.call(arg, -1, None, None, outFile, errorFile)
	    # Check the process exit code, print error information if it exists
	    if not retval == 0:  
		errData = errorFile.read()
		raise Exception("Error executing command: " + repr(errData))
	      
if __name__=="__main__":
  main(sys.argv[1:])