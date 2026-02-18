using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class LoadingScreen : MonoBehaviour
{
    public static string nextSceneName;

    [SerializeField] private Slider progressBar; // optional

    private void Start()
    {
        StartCoroutine(LoadAsync());
    }

    private IEnumerator LoadAsync()
    {
        if (string.IsNullOrEmpty(nextSceneName))
            nextSceneName = "GameScene";

        AsyncOperation op = SceneManager.LoadSceneAsync(nextSceneName);
        op.allowSceneActivation = false;

        while (op.progress < 0.9f)
        {
            float p = Mathf.Clamp01(op.progress / 0.9f);
            if (progressBar != null) progressBar.value = p;
            yield return null;
        }

        if (progressBar != null) progressBar.value = 1f;

        yield return new WaitForSeconds(0.15f);
        op.allowSceneActivation = true;
    }
}
