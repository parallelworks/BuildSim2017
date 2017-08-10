#!/usr/bin/python

import sys


def main(params_string, params_file):
    new_params_string = params_string.replace(',', '\n').replace(':', ': ')

    with open(params_file, 'w') as f:
        f.write(new_params_string)


if __name__ == '__main__':
    params_string = sys.argv[1]
    params_file = sys.argv[2]

    main(params_string, params_file)

