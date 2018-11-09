# show-gits

I have several git repos sprinkled throughout my `$HOME` directory. I wrote a one-liner to fine them:

`find ~ -type d -name .git 2>/dev/null | xargs -n 1 dirname`

This actually works quite well. It is nice, however, to be able to see the status of each repo and see if there are any conflicted files lurking in the directory tree.

This script will do just that! *And* you can pipe it to vim and work some netrw wizardry on it to navigate to the repos or files in question and do whatever needs to be done:

`show-gits | vim -`

More to follow...

Found isnpiration here https://gist.github.com/mzabriskie/6631607
