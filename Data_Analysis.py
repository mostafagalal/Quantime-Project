import pandas as pd 
import numpy as np 

def gen_stats(col):
    if col.dtypes == 'O' or col.dtypes == 'object' or col.dtypes == 'str':
        print("Sorry the mentioned Column is String")
        
    else:
        describe = col.describe()
        mean = describe["mean"]
        median = col.median()
        min_value = describe["min"]
        max_value = describe["max"]
        q1 = describe["25%"]
        q3 = describe["75%"]
        iqr = q3 - q1
        upperOut = (q3 + iqr  * 1.5)
        lowerOut = (q1 - iqr  * 1.5)
        std = describe["std"]
        val_below_outlier = col[col < lowerOut].count()
        val_above_outlier = col[col > upperOut].count()
        z_score = ( col - np.mean(col) ) / std
        z_robust_median = np.median(col)
        z_robust_mad = np.median(np.abs(col - z_robust_median ))
        z_robust_score =  (col - z_robust_median ) / (1.4826 * z_robust_mad  )
        
        stats = {
            "Mean" : mean,
            "Median" : median,
            "Std": std,
            "Min": min_value,
            "Max": max_value,
            "Q1": q1,
            "Q3": q3,
            "IQR": iqr,
            "Lower_Outlier": lowerOut,
            "Upper_Outlier": upperOut,
            "Values below outlier" : val_below_outlier,
            "Values above outlier" : val_above_outlier,
            "Total count of values" : col.shape[0],
            "z_score > 1" : (z_score > 1).sum(),
            "z_score > 2" : (z_score > 2).sum(),
            "z_score > 3" : (z_score > 3).sum(),
            "MAD Z-Robust-Score" : z_robust_mad,
            "Z-Robust-Score > 1 " : (np.abs(z_robust_score) > 1).sum() if (z_robust_mad != 0  and pd.notna(z_robust_mad)  ) else "Not applciable mad = 0 or None ",
            "Z-Robust-Score > 2 " : (np.abs(z_robust_score) > 2).sum() if (z_robust_mad != 0  and pd.notna(z_robust_mad)  ) else "Not applciable mad = 0 or None ",
            "Z-Robust-Score > 3 " : (np.abs(z_robust_score) > 3).sum() if (z_robust_mad != 0  and pd.notna(z_robust_mad)  ) else "Not applciable mad = 0 or None "            
        }
        
    
        return pd.Series(stats).round(0) 



import pandas as pd

def top_n(df, group_col, sum_col=None, n=5, mode='sum', observed=None):
    """
    top_n: return top N groups by sum or count

    Parameters
    ----------
    df : pandas.DataFrame
    group_col : str or list[str] or int  # column name or list of names or index
    sum_col : str or list[str] or None   # required when mode='sum'
    n : int or None                      # if None return all
    mode : 'sum' or 'count' (case-insensitive)
    observed : bool or None              # if None -> auto-detect categorical
    """
    # normalize group_col to list (avoid list-in-list)
    if not isinstance(group_col, list):
        group_col = [group_col]

    # determine observed if not provided
    if observed is None:
        observed = any(pd.api.types.is_categorical_dtype(df[col]) for col in group_col)

    # normalize mode
    mode = (mode or 'sum').lower()

    if mode == 'sum':
        if sum_col is None:
            raise ValueError("sum_col must be provided when mode='sum'")

        # support sum_col as string or list
        if not isinstance(sum_col, list):
            # single column -> result is Series -> reset_index with name
            result = (
                df.groupby(group_col, observed=observed)[sum_col]
                  .sum()
                  .reset_index(name=f"Total_of_{sum_col}")
                  .sort_values(by=f"Total_of_{sum_col}", ascending=False)
                  .reset_index(drop=True)
            )
        else:
            # multiple sum columns -> sum returns DataFrame
            result = (
                df.groupby(group_col, observed=observed)[sum_col]
                  .sum()
                  .reset_index()
                  .sort_values(by=sum_col[0], ascending=False)  # default sort by first agg column
                  .reset_index(drop=True)
            )

    elif mode == 'count':
        # count occurrences of group combinations
        # use size() to count rows per group
        result = (
            df.groupby(group_col, observed=observed)
              .size()
              .reset_index(name='Count')
              .sort_values(by='Count', ascending=False)
              .reset_index(drop=True)
        )

    else:
        raise ValueError("mode must be 'sum' or 'count'")

    # apply head if n is specified
    if n is not None:
        return result.head(n)
    return result
