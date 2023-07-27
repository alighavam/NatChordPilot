# making target files for the natural-chord EMG experiment
# Ali Ghavampour - 2023

import itertools
import random
import numpy as np
import pandas as pd

def gen_single_finger(single_finger_chords, column_names, nChunks, nRep, subNum, planTime, execMaxTime, feedbackTime, iti, fileNameBase):
    # function for making the first run - single finger

    # turning chords list into numpy array:
    single_finger_chords = np.array(single_finger_chords)

    # repeating chords for nChunks number:
    single_finger_chords = np.repeat(single_finger_chords, nChunks, axis=0)

    # shuffling the chords:
    np.random.shuffle(single_finger_chords)

    # repeating the chords:
    single_finger_chords = np.repeat(single_finger_chords, int(nRep/nChunks), axis=0)

    # generating the columns:
    col01 = subNum * np.ones(np.size(single_finger_chords,0), dtype=int)
    col03 = planTime * np.ones(np.size(single_finger_chords,0), dtype=int)
    col04 = execMaxTime * np.ones(np.size(single_finger_chords,0), dtype=int)
    col05 = feedbackTime * np.ones(np.size(single_finger_chords,0), dtype=int)
    col06 = iti * np.ones(np.size(single_finger_chords,0), dtype=int)

    # building the dataframe:
    df = pd.DataFrame(columns=column_names)
    df['subNum'] = col01
    df['chordID'] = single_finger_chords
    df['planTime'] = col03
    df['execMaxTime'] = col04
    df['feedbackTime'] = col05
    df['iti'] = col06

    # saving the first run dataframe:
    fname = fileNameBase + f"{1:02}" + '.tgt'
    df.to_csv('target/'+fname, sep='\t', index=False)

def gen_chords(chords, column_names, nChunks, nRep, subNum, planTime, execMaxTime, feedbackTime, iti, fileNameBase):
    # function to generate target files for the chords - Note that chords are hard coded in the pilot study. Just randomly selected some of the most difficut chords
    # that we acquired from the 6 subject experiment. The difficulty measure was Mean Deviation. So, we have assumed that higher mean dev means higher difficulty on average.
    # In the future experiments there should be a pool of difficult chords to randomly select from rather than hard coding them.

    # turning chords list into numpy array:
    chords = np.array(chords)

    # repeating chords for nChunks number:
    chords = np.repeat(chords, nChunks, axis=0)

    # shuffling the chords:
    np.random.shuffle(chords)

    # dividing chords into runs:
    nRuns = nChunks # number of runs to divide. the value is arbitrary. I just selected in a way that the number of chords is dividable by this number.
    divisions = np.split(chords, nRuns)

    # looping through divisions and creating target files:
    for i in range(len(divisions)):
        # repeating the chords:
        chords_tmp = np.repeat(divisions[i], int(nRep/nChunks), axis=0)

        # generating the target file columns:
        col01 = subNum * np.ones(np.size(chords_tmp,0), dtype=int)
        col03 = planTime * np.ones(np.size(chords_tmp,0), dtype=int)
        col04 = execMaxTime * np.ones(np.size(chords_tmp,0), dtype=int)
        col05 = feedbackTime * np.ones(np.size(chords_tmp,0), dtype=int)
        col06 = iti * np.ones(np.size(chords_tmp,0), dtype=int) 

        # building the dataframe:
        df = pd.DataFrame(columns=column_names)
        df['subNum'] = col01
        df['chordID'] = chords_tmp
        df['planTime'] = col03
        df['execMaxTime'] = col04
        df['feedbackTime'] = col05
        df['iti'] = col06

        # saving the dataframe:
        fname = fileNameBase + f"{i+2:02}" + '.tgt'
        df.to_csv('target/'+fname, sep='\t', index=False)


# Chords definition:
single_finger_chords = [] # empty list of single finger chords
chords = [] # empty list of chords
single_finger_chords.extend(np.unique(list(itertools.permutations([1,9,9,9,9])), axis=0).tolist()) # single finger extensions
single_finger_chords.extend(np.unique(list(itertools.permutations([2,9,9,9,9])), axis=0).tolist()) # single finger flexions
chords.extend([[1,1,9,1,2],[2,2,9,2,1],[2,1,9,1,1],[1,2,9,2,2]])  # chord 1 + mirrors
chords.extend([[1,2,1,9,1],[2,1,2,9,2],[1,9,1,2,1],[2,9,2,1,2]])  # chord 2 + mirrors
chords.extend([[1,2,1,1,2],[2,1,2,2,1],[2,1,1,2,1],[1,2,2,1,2]])  # chord 3 + mirrors
chords.extend([[1,1,2,1,2],[2,2,1,2,1],[2,1,2,1,1],[1,2,1,2,2]])  # chord 4 + mirrors

# Joining the elements of the chords:
single_finger_chords = [int(''.join(map(str, sublist))) for sublist in single_finger_chords]
chords = [int(''.join(map(str, sublist))) for sublist in chords]

# Params:
nChords = len(chords)   # number of chords
nRep = 20           # number of repetition of each chord
nChunks = 4         # number of chunks to repeat chords
planTime = 500      # time for planning
execMaxTime = 10000 # maximum time for execution
feedbackTime = 800  # time to present feedback
iti = 200           # inter-trial interval

# column names:
column_names = ['subNum', 'chordID', 'planTime', 'execMaxTime', 'feedbackTime', 'iti']


# setting the subject number !!!-------- Don't forget to change --------!!!:
subNum = 2 
fileNameBase = 'natChord_subj' + f"{subNum:02}" + '_run'

# generating and saving the target file for single finger run:
gen_single_finger(single_finger_chords, column_names, nChunks, nRep, subNum, planTime, execMaxTime, feedbackTime, iti, fileNameBase)

# generating and saving the target file for chord runs:
gen_chords(chords, column_names, nChunks, nRep, subNum, planTime, execMaxTime, feedbackTime, iti, fileNameBase)
