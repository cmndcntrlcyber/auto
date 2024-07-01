# Adds "https://' at the beginning of a newline for bounty tools
import sys

target = str(sys.argv[1])

# Open the file
with open(target, 'r') as f:
    lines = f.readlines()

#Remove astriks at the end of the line
remove_astriks = []
for ra, line in enumerate(lines):
     line = line.strip("*")

#Remove astriks at the end of the line
remove_astriks = []
for ra, line in enumerate(lines):
     line = line.strip('/"')

new_lines = []
for i, line in enumerate(lines):
    # strip newline character from the end of the string
    line = line.strip()
    
    if not line.startswith('https://'):
        # append to previous line if it exists
        if new_lines:
                new_lines[-1] += '\n' + "https://" + line
        else:
            # add to the list as is, we cannot prepend because there are no lines yet
            new_lines.append(line)
    else:
        new_lines.append(line)

# now write back to file
with open('domains-new.txt', 'w') as f:
    for line in new_lines:
        # add newline character back
        f.write(line + '\n')